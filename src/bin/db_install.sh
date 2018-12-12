#!/bin/bash

## exit on errors
set -e

#
# Install DB on dev enviroment
#

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MAGENTO_DIR="${SCRIPT_DIR}/.."
COMPOSER_DIR=${MAGENTO_DIR}
sqlfile=$1

source ${SCRIPT_DIR}/config.sh

if [[ $1 == '--help' || $1 == '-h' ]]
	then
	echo  "use: ./db_install.sh <file>"
	echo  "<file>      dump-sql-to-import.sql"
	exit;
fi

if [[ -z $sqlfile  ]]
	then
	if [[ -z $remote_host || -z $remote_hostuser ||  -z $remote_hostpass || -z remote_dbhost || -z $remote_dbuser ||  -z $remote_dbpass || -z $remote_dbname ]]
		then
		echo "The all remotes params in config.sh are required if no pass file.sql like first parameter"
		exit;
	fi

	echo "Try dumping db ${remote_dbname} from host ${remote_dbhost} ... "
	localdbname=${remote_dbname}-$(date +%Y-%m-%d-%H.%M.%S).sql.gz
	ssh -l ${remote_hostuser} ${remote_host} "mysqldump --u ${remote_dbuser} -p${remote_dbpass} -h ${remote_dbhost} ${remote_dbname} | gzip -3 -c" > ${SCRIPT_DIR}/${localdbname}
	
	if [ $? -eq 0 ]; then
	    echo "${remote_dbname} dumped succesfully from ${remote_host} and placed in : ${SCRIPT_DIR}/${localdbname}"
	    sqlfile=${localdbname}

	else
	    echo "Some error occurred when trying to dumping ${remote_dbname} from host ${remote_host}"
	    exit;
	fi
fi

cd ${MAGENTO_DIR}

# if local not exits delete it
if [ ! -f ${MAGENTO_DIR}/app/etc/local.xml ] ; then
	echo "File local.xml not exits, try to generate it"

	if [ ! -f ${MAGENTO_DIR}/app/etc/local.xml.template ] ; then
		echo "File local.xml.template not exits in project, copy from M. v1.9"
		cp -f ${SCRIPT_DIR}/local.xml.template  app/etc/local.xml.template
	fi;

   	n98-magerun.phar local-config:generate $dbhost $dbuser $dbpass $dbname files admin
fi

n98-magerun.phar db:drop --force
echo "Database local deleted succesfully"
n98-magerun.phar db:create;
echo "Database local created succesfully"


DB_DUMP=${SCRIPT_DIR}/${sqlfile}
if [ ! -f ${DB_DUMP} ] ; then
	echo  "A ${DB_DUMP} not found"
	exit;
fi


if [ ${sqlfile: -3} == ".gz" ] ; then
	n98-magerun.phar db:import -c gz ${DB_DUMP}
elif [ ${sqlfile: -4} == ".tgz" ]; then
	echo "Foud the .tgz compresed file, uncompress for import"
	pv ${DB_DUMP} | tar -xz

	n98-magerun.phar db:import -c tgz ${DB_DUMP}
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
