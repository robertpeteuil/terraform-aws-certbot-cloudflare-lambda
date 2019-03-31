"""Cerbot management of LetsEncrypt Certificates for Cloudflare domains."""

import os
import boto3
import certbot.main


# set global vars
DEBUG = os.getenv('test_cert', False)
topic_arn = os.getenv('sns_topic_arn', '')


def main(event, context):
    try:
        domains = os.environ['letsencrypt_domains']
        email = os.environ['letsencrypt_email']
        s3_bucket = os.environ['s3_bucket']
        s3_path = os.environ['s3_path']
    except KeyError:
        print("LetsEncrypt Environment Variables not set.")
        raise
    get_dns_creds(s3_bucket, s3_path)
    (primary_domain, path) = provision_cert(email, domains)
    upload_to_s3(primary_domain, path, s3_bucket, s3_path)
    sns_logit(domains)
    return


def get_dns_creds(s3_bucket, s3_path):
    """Retrieve cloudflare.ini from S3."""
    s3 = boto3.resource('s3')
    s3.meta.client.download_file(s3_bucket, s3_path + '/dns/cloudflare.ini', '/tmp/cloudflare.ini')


def upload_to_s3(primary_domain, path, s3_bucket, s3_path):
    """Copy Certificates to S3."""
    extra_args = {'ServerSideEncryption': 'AES256'}
    s3 = boto3.resource('s3')

    for keyname in ['fullchain.pem', 'privkey.pem', 'cert.pem', 'chain.pem']:
        dest_filename = "{}/live/{}/{}".format(s3_path, primary_domain, keyname)
        s3.meta.client.upload_file(path + keyname, s3_bucket, dest_filename, ExtraArgs=extra_args)
        print("{} uploaded".format(dest_filename))
        os.remove(path + keyname)


def provision_cert(email, domains):
    """Execute certbot using cloudflare plugin."""
    cert_config = [
        'certonly',                             # Obtain a cert but don't install it
        '-n',                                   # Run in non-interactive mode
        '--agree-tos',                          # Agree to the terms of service,
        '--email', email,                       # Email
        '--dns-cloudflare',                     # Use the Cloudflare dns plugin
        '--dns-cloudflare-credentials', '/tmp/cloudflare.ini',  # plugin auth
        '-d', domains,                          # Domains to provision certs for
        '--config-dir', '/tmp/config-dir/',     # Override directory paths for lambda
        '--work-dir', '/tmp/work-dir/',         # Override directory paths for lambda
        '--logs-dir', '/tmp/logs-dir/',         # Override directory paths for lambda
    ]

    if DEBUG:
        cert_config.append('--test-cert')

    certbot.main.main(cert_config)

    primary_domain = domains.split(',')[0]
    path = '/tmp/config-dir/live/' + primary_domain + '/'

    return (primary_domain, path)


def sns_logit(domains):
    """Write supplied message to SNS topic."""
    if topic_arn:
        sns = boto3.client('sns')
        try:
            sns.publish(TopicArn=topic_arn,
                        Subject="CERBOT_CLOUDFLARE - ",
                        Message='Issued new certificates for domains: ' + domains)
        except:
            pass
    else:
        print("CERBOT_CLOUDFLARE - Issued new certificates for domains: " + domains)
    return
