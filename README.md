# Carbonio NGINX Conf

![Contributors](https://img.shields.io/github/contributors/zextras/carbonio-jetty-conf "Contributors")
![Activity](https://img.shields.io/github/commit-activity/m/zextras/carbonio-jetty-conf "Activity") ![License](https://img.shields.io/badge/license-GPL%202-green
"License")
![Project](https://img.shields.io/badge/project-carbonio-informational
"Project")
[![Twitter](https://img.shields.io/twitter/url/https/twitter.com/zextras.svg?style=social&label=Follow%20%40zextras)](https://twitter.com/zextras)

NGINX configuration resources for Carbonio

## Makefile Overview

For almost every command you need to pass the `HOST` enviroment variable in order to tell which cluster you want to reach.

For example:
```shell
$ HOST=hostname.zextras.io make sys-deploy
```

Summary of the available commands:

- build: create the `.deb` package under `artifacts` folder
- sys-install: copy and install latest built `.deb` package in a remote server
- sys-deploy: build, install and restart the service in a remote server
- sys-status|start|stop|restart: Check or control via SSH the service into the specified host

## License

See [COPYING](COPYING) file for details
