# Magento1 Dev tools

Magento tools for developers

## Required
* Modman: For more info  about visit [https://github.com/colinmollenhour/modman](https://github.com/colinmollenhour/modman)

## Features
The features inclued in this module are utitlities and modules for developers

### Modules for dev

* [Easy Path Hints Module]((http://www.magepsycho.com/easy-template-path-hints.html)): Easy Template Path Hints extension is used to turn on the template path hints for frontend & backend with ease in a secured way.  Moreover it's joomla way of turning on the template path hints 

### Utils
The utils bash scritpt are under bin/
You need create a config file 
```
cp bin/config.sh.dist  bin/config.sh
```
 and then set the params (dbhost,dbuser, etc)

#### Database install 

Run Import 
```
./bin/db_install.sh dumpdb.sql
```

Import in dev enviroment a database dump: 
 * change base url,
 * disable cache , 
 * disable send emails, 
 * disable Google Analytics,
 * install composer dependencies,
 * clean cache
 * reindex all 


### Installing

and then 
```
modman clone git@github.com:victordit/magento1_devtools.git
```

That's all.


## Contributing

Fork repository, checkout develop branch, commit your modifications and create a pull request

## Versioning

See tags for check version
