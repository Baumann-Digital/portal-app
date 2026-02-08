[![BauDi Logo](https://raw.githubusercontent.com/Baumann-Digital/portal-app/develop/resources/img/logo_baudi.png)](https://baumann-digital.de/)

# BauDi portal-app

![dev build](https://github.com/Baumann-Digital/portal-app/actions/workflows/dev-build.yml/badge.svg)

![prod build](https://github.com/Baumann-Digital/portal-app/actions/workflows/prod-build.yml/badge.svg)

[![GitHub Release](https://img.shields.io/github/release/Baumann-Digital/portal-app.svg?style=flat)]()

---

[![deepwiki](https://deepwiki.com/badge-maker?url=https%3A%2F%2Fdeepwiki.com%2FBaumann-Digital%2Fportal-app)](https://deepwiki.com/badge-maker?url=https%3A%2F%2Fdeepwiki.com%2FBaumann-Digital%2Fportal-app)

---

[![fair-software.eu](https://img.shields.io/badge/fair--software.eu-%E2%97%8F%20%20%E2%97%8F%20%20%E2%97%8B%20%20%E2%97%8B%20%20%E2%97%8B-orange)](https://fair-software.eu)
[![License BSD2](https://img.shields.io/badge/license-BSD2-green.svg)](https://github.com/Baumann-Digital/portal-app/blob/develop/LICENSE)
[![License CCBY](https://img.shields.io/badge/license-CC--BY--4.0-green.svg)](https://raw.githubusercontent.com/Baumann-Digital/portal-app/develop/LICENSE)

</div>

This web application is written in XQuery on top of an [eXist-db](http://exist-db.org) and powers [baumann-digital.de](https://baumann-digital.de).


## Prerequisites

A recent [eXist-db 6.X](http://exist-db.org/) 

## Quick start guide

If you have a running eXist database you can simply install the `portal-app.xar` from the [Release section](https://github.com/Baumann-Digital/portal-app/releases) via the eXist-Dashboard.

### Dependencies on other eXist apps/libs

installable via dashboard:
* `functx` (1.X.X or higher)
* `html-templating` (1.X.X or higher)
* `shared` (0.9.X or higher)

## Branches

* `main`: stable branch, i.e. the current release version
* `develop`: development branch
* other branches are experimental and and will get merged (or just some features) into develop at some point

## How to build

* installing [Apache Ant](https://ant.apache.org)
* running `ant` from the repository root

## Documentation

under construction.


## License

This work is available under dual license: [BSD 2-Clause](http://opensource.org/licenses/BSD-2-Clause) and [Creative Commons Attribution 4.0 International License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/)
