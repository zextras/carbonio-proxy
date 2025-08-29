# Changelog

## [4.9.3](https://github.com/zextras/carbonio-proxy/compare/4.9.2...4.9.3) (2025-08-29)

## [4.9.2](https://github.com/zextras/carbonio-proxy/compare/4.9.0...4.9.2) (2025-08-25)


### Bug Fixes

* sidecar-units: revert WantedBy for compatibility with older systems ([#148](https://github.com/zextras/carbonio-proxy/issues/148)) ([2ce986f](https://github.com/zextras/carbonio-proxy/commit/2ce986f658acff03a951d6f358c12ac4a480120e))

## [4.8.1](https://github.com/zextras/carbonio-proxy/compare/4.8.0...4.8.1) (2025-02-17)


### Bug Fixes

* [CO=1822] pass X-Forwarded-Proto header to upstream ([#136](https://github.com/zextras/carbonio-proxy/issues/136)) ([5249246](https://github.com/zextras/carbonio-proxy/commit/52492463483ebbed9b4ada7d2368b5f8d17bc0fc))

# [4.7.0](https://github.com/zextras/carbonio-proxy/compare/4.6.0...4.7.0) (2024-02-15)


### Bug Fixes

* *.hcl: apply corrections to validate with hclfmt ([#105](https://github.com/zextras/carbonio-proxy/issues/105)) ([0567358](https://github.com/zextras/carbonio-proxy/commit/0567358f4109b2e449cefebc40214ed3222116fd))
* use correct proxy var to expand virtual host headers ([ce272f8](https://github.com/zextras/carbonio-proxy/commit/ce272f82ce711ea32140aca6ec761743bafb50f3))


### Features

* [FILES-725] handle missing cookies for collaboration links ([#97](https://github.com/zextras/carbonio-proxy/issues/97)) ([237d618](https://github.com/zextras/carbonio-proxy/commit/237d618aa248ec275741865ae69f7c860df5a167))
* [FILES-725] handle missing cookies for collaboration links ([#97](https://github.com/zextras/carbonio-proxy/issues/97)) ([4ec8900](https://github.com/zextras/carbonio-proxy/commit/4ec8900a1b0e5511aa4cd5772d506e4e5c0f2e91))

# [4.6.1](https://github.com/Zextras/carbonio-proxy/compare/4.6.0...4.6.1) (2023-11-29)


### Bug Fixes

* **config:** [CO-901] use correct proxy var to expand virtual host response headers ([3f789b8](https://github.com/Zextras/carbonio-proxy/commit/3f789b8849f3a9036deec1ca7bed208d0d897f75))

# [4.6.0](https://github.com/Zextras/carbonio-proxy/compare/4.5.1...4.6.0) (2023-11-24)


### Bug Fixes

* **ci:** packages are not uploaded ([7d18cd4](https://github.com/Zextras/carbonio-proxy/commit/7d18cd491d094983d6d23e888cd9d686977d813d))
* fix rpm uploads ([b47c36e](https://github.com/Zextras/carbonio-proxy/commit/b47c36ef24b161b893578d732f74bdb731ccebdf))


### Features

* add nginx rule to fetch carbonio-files-public-folder-ui bundle ([#96](https://github.com/Zextras/carbonio-proxy/issues/96)) ([d780b06](https://github.com/Zextras/carbonio-proxy/commit/d780b06eb6f70252f7be5d359c8484bef681a246))

## [4.5.1](https://github.com/Zextras/carbonio-proxy/compare/4.5.0...4.5.1) (2023-11-09)

# [4.5.0](https://github.com/Zextras/carbonio-proxy/compare/4.4.0...4.5.0) (2023-10-20)


### Bug Fixes

* Carbonio shows Jetty favicon instead of Carbonio one ([#90](https://github.com/Zextras/carbonio-proxy/issues/90)) ([8cbfc4a](https://github.com/Zextras/carbonio-proxy/commit/8cbfc4af1d21cc14699a1e37057319d9891f0b31))


### Features

* add ubuntu 22.04 (jammy jellyfish) support ([#87](https://github.com/Zextras/carbonio-proxy/issues/87)) ([ee368fd](https://github.com/Zextras/carbonio-proxy/commit/ee368fd2e99f9b4652d9ae92ae8058df3ff43a4f))
* add ubuntu 22.04 (jammy jellyfish) support ([#87](https://github.com/Zextras/carbonio-proxy/issues/87)) ([9c0b62e](https://github.com/Zextras/carbonio-proxy/commit/9c0b62e3ed26665ac491cc0a953f85da0821a14e))
* move to yap agent and add rhel9 support ([6cd2579](https://github.com/Zextras/carbonio-proxy/commit/6cd2579976e5b46a8529db63e3d6dc3fe9b107a6))
* move to yap agent and add rhel9 support ([#88](https://github.com/Zextras/carbonio-proxy/issues/88)) ([e2de359](https://github.com/Zextras/carbonio-proxy/commit/e2de359c20092afd48ebcb6b40eb31e66a9d874b))

# [4.4.0](https://github.com/Zextras/carbonio-proxy/compare/4.3.0...4.4.0) (2023-09-26)


### Features

* add logout endpoint to handle user logout([#80](https://github.com/Zextras/carbonio-proxy/issues/80)) ([f40f3ed](https://github.com/Zextras/carbonio-proxy/commit/f40f3edc8ecf5633f1ad122046c14c803486bba5))
* Add support for custom login/logout URL for domains ([6c988b0](https://github.com/Zextras/carbonio-proxy/commit/6c988b04f808b00f8bc9e5ad5b3bca4bf4d4ed34))

# [4.3.0](https://github.com/Zextras/carbonio-proxy/compare/4.1.1...4.3.0) (2023-08-28)


### Features

* [CO-767] Remove UI cookie logic + minor improvements ([#75](https://github.com/Zextras/carbonio-proxy/issues/75)) ([76bb781](https://github.com/Zextras/carbonio-proxy/commit/76bb78150dd2246fb09c18a8d6d28ddd70e15348))

# [4.1.0](https://github.com/Zextras/carbonio-proxy/compare/4.0.18...4.1.0) (2023-07-05)


### Features

* [CO-677] Change path of service acl policy token ([#73](https://github.com/Zextras/carbonio-proxy/issues/73)) ([4c8bbf4](https://github.com/Zextras/carbonio-proxy/commit/4c8bbf4045a32eb800388df9b4dd761aad9aba68))

## [4.0.18](https://github.com/Zextras/carbonio-proxy/compare/4.0.17...4.0.18) (2023-05-18)
