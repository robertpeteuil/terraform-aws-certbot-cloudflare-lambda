# terraform-aws-certbot-cloudflare-lambda Changelog

All notable changes to this project will be documented in this file.

This project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2021-08-23

- updated Certbot to 1.18
- updated certbot-dns-cloudflare
- switched to Cloudflare API token auth
- added wildcard domain certificate support
- bumped Python runtime to 3.7

## [2.0.0] - 2019-05-27

- update for HCL2 in Terraform versions > 0.12
- constrain AWS provider for terraform 0.12 version >= 2.12
- added CHANGELOG.md

## [1.1.4] - 2019-05-27

- Update base layer for new Lambda runtime environment

## [1.1.3] - 2019-05-08

- Documentation Adjustments

## [1.1.2] - 2019-04-12

- constrain AWS provider to versions >= 2.0
  - necessary due to [attribute values swap](https://www.terraform.io/docs/providers/aws/guides/version-2-upgrade.html#arn-and-layer_arn-attribute-value-swap) in versiions >= 2.0

## [1.1.1] - 2019-03-30

- update README.md

## [1.1.0] - 2019-03-30

- Add Terraform Major version pinning and aws region

## [1.0.0] - 2019-03-30

- Initial Release

[2.0.0]: https://github.com/robertpeteuil/terraform-aws-certbot-cloudflare-lambda/compare/1.1.4...2.0.0
[1.1.4]: https://github.com/robertpeteuil/terraform-aws-certbot-cloudflare-lambda/compare/1.1.3...1.1.4
[1.1.3]: https://github.com/robertpeteuil/terraform-aws-certbot-cloudflare-lambda/compare/1.1.2...1.1.3
[1.1.2]: https://github.com/robertpeteuil/terraform-aws-certbot-cloudflare-lambda/compare/1.1.1...1.1.2
[1.1.1]: https://github.com/robertpeteuil/terraform-aws-certbot-cloudflare-lambda/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/robertpeteuil/terraform-aws-certbot-cloudflare-lambda/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/robertpeteuil/terraform-aws-certbot-cloudflare-lambda/tree/1.0.0
