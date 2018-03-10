#!/bin/bash

#
# Install DB on dev enviroment
#


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MAGENTO_DIR="${SCRIPT_DIR}/.."
COMPOSER_DIR=${MAGENTO_DIR}
sqlfile=$1


if [[ $1 == '--help' || $1 == '-h' ]]
	then
	echo  "use: ./db_install.sh <file>"
	echo  "<file>      dump-sql-to-import.sql"
	exit;
fi

if [[ -z $sqlfile  ]]
	then
	echo  "A 'file.sql' is required for import a new db"
	exit;
fi

DB_DUMP=${SCRIPT_DIR}/${sqlfile}
if [ ! -f ${DB_DUMP} ] ; then
	echo  "A ${DB_DUMP} not found"
	exit;
fi

source ${SCRIPT_DIR}/config.sh

cd ${MAGENTO_DIR}

# if db exits delete it
if [ -f ${MAGENTO_DIR}/app/etc/local.xml ] ; then
    n98-magerun.phar db:drop --force
    rm ${MAGENTO_DIR}/app/etc/local.xml
fi

n98-magerun.phar local-config:generate $dbhost $dbuser $dbpass $dbname files admin
n98-magerun.phar db:create
if [ ${sqlfile: -3} == ".gz" ] ; then
	n98-magerun.phar db:import -c gz ${DB_DUMP}
else
	n98-magerun.phar db:import ${DB_DUMP}
fi

echo -e ""
echo -e "\033[37;44m            \033[0m"
echo -e "\033[37;44m  Base Url  \033[0m"
echo -e "\033[37;44m            \033[0m"
echo -e ""
n98-magerun.phar config:set web/secure/base_url ${baseurl}
n98-magerun.phar config:set web/unsecure/base_url ${baseurl}
n98-magerun.phar config:set admin/url/use_custom 0
n98-magerun.phar config:set admin/url/use_custom_path 0

if [[ $adminuser && $adminpass ]] ; then
	echo -e ""
	echo -e "\033[37;44m                  \033[0m"
	echo -e "\033[37;44m  Admin Password  \033[0m"
	echo -e "\033[37;44m                  \033[0m"
	echo -e ""
	n98-magerun.phar admin:user:change-password ${adminuser} ${adminpass}
fi

echo -e ""
echo -e "\033[37;44m                   \033[0m"
echo -e "\033[37;44m  Disabling Cache  \033[0m"
echo -e "\033[37;44m                   \033[0m"
echo -e ""
n98-magerun.phar cache:disable

echo -e ""
echo -e "\033[37;44m                   \033[0m"
echo -e "\033[37;44m  Disabling Email  \033[0m"
echo -e "\033[37;44m                   \033[0m"
echo -e ""
n98-magerun.phar config:set system/smtp/disable "1"

echo -e ""
echo -e "\033[37;44m                              \033[0m"
echo -e "\033[37;44m  Disabling Google Analytics  \033[0m"
echo -e "\033[37;44m                              \033[0m"
echo -e ""
n98-magerun.phar config:delete --all google/analytics/account
n98-magerun.phar config:delete --all google/analytics/active
n98-magerun.phar config:delete --all google/analyticsplus/conversionenabled
n98-magerun.phar config:set google/analytics/active 0
n98-magerun.phar config:set google/analyticsplus/conversionenabled 0

echo -e ""
echo -e "\033[37;44m                           \033[0m"
echo -e "\033[37;44m  Installing dependencies  \033[0m"
echo -e "\033[37;44m                           \033[0m"
echo -e ""

if [ -f ${COMPOSER_DIR}/composer.json ] ; then
    cd ${COMPOSER_DIR} && composer install && cd ${MAGENTO_DIR}
fi

echo -e ""
echo -e "\033[37;44m                  \033[0m"
echo -e "\033[37;44m  Cleaning Cache  \033[0m"
echo -e "\033[37;44m                  \033[0m"
echo -e ""
cd ${MAGENTO_DIR}
n98-magerun.phar cache:clean

echo -e ""
echo -e "\033[37;44m           \033[0m"
echo -e "\033[37;44m  Reindex  \033[0m"
echo -e "\033[37;44m           \033[0m"
echo -e ""
cd ${MAGENTO_DIR}
n98-magerun.phar index:reindex:all


##
## You can add others config for set new configurations for dev env or enabled/disabled modules with magerun
#

# echo -e ""
# echo -e "\033[37;44m                              \033[0m"
# echo -e "\033[37;44m  Disabling My Module         \033[0m"
# echo -e "\033[37;44m                              \033[0m"
# echo -e ""
# n98-magerun.phar dev:module:disable MyVendor_MyModule

# echo -e ""
# echo -e "\033[37;44m                              \033[0m"
# echo -e "\033[37;44m  Set My configurations       \033[0m"
# echo -e "\033[37;44m                              \033[0m"
# echo -e ""
# n98-magerun.phar dev:module:disable MyVendor_MyModule
#n98-magerun.phar config:set custom/path custom_value
#n98-magerun.phar config:set custom/path custom_value