#!/bin/bash


# Pass config file to this script. Example: sh backup.sh my_website
CONFIG_FILE=$( dirname "${BASH_SOURCE[0]}" )/$1".config"
echo "Read config file ${CONFIG_FILE}"
source ${CONFIG_FILE}


# set version
websitebackup_version="1.1.0"
# set date
websitebackup_date="11.04.2019"
# set author
websitebackup_author="Daniel Ruf (https://daniel-ruf.de) & Matthias Schobner (https://www.schobner.rocks)"

# output program information
echo "website backup $websitebackup_version ($websitebackup_date) by $websitebackup_author"


# set date
datestr=$(date +"%Y_%m_%d")

# set time
timestr=$(date +"%H_%M_%S")

# set backup directory name
backupname="${datestr}_${timestr}"


# set connection details
ssh_connection="${ssh_user}@${ssh_host}"
mysql_connection="-h ${db_host} -u ${db_user} -p'${db_password}' ${db_name}"


# set remote files
tar_file="${backups_path}${backupname}_files.tar.gz"
sql_file="${backups_path}${backupname}_database.sql"


ssh ${ssh_connection} << EOF
    # create remote backup directory
    mkdir -p ${backups_path} && echo 'remote backup directory created'

    # clean up remote backup directory
    rm -rfv ${backups_path}* && echo 'remote backup directory cleaned up'

    # create remote files backup
    tar cfpz ${tar_file} ${website_path} && echo 'remote files backup completed'

    # create remote database backup
    mysqldump ${mysql_connection} --result-file=${sql_file} && echo 'remote database backup completed'
EOF


# create local backup directory
mkdir "backups_${1}" && echo 'created local backup directory "backups_'$1'"'


# download remote files backup
scp ${ssh_connection}:${tar_file} "backups_${1}/${backupname}_files.tar.gz" && echo downloaded remote files backup

# download remote database backup
scp ${ssh_connection}:${sql_file} "backups_${1}/${backupname}_database.sql" && echo downloaded remote database backup


ssh ${ssh_connection} << EOF
    rm ${tar_file} && echo 'deleted remote files backup'

    rm ${sql_file} && echo 'deleted remote database backup'

    rm -rfv ${backups_path}* && echo 'remote backup directory cleaned up'
EOF
