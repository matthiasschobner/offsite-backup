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
backupname=$datestr"_"$timestr


# set connection details
connection_details="$ssh_user@$ssh_host"

# set plink connection
connection_plink="plink -ssh $connection_details"

# get more details like the hostkey
# connection_plink="plink -v -ssh $connection_details"

# set pscp connection
connection_pscp="pscp -sftp $connection_details"


ssh $connection_details << EOF
    set -xe

    # clean up remote backup directory
    rm -rfv ${backups_path} && echo 'remote backup directory cleaned up'

    # create remote backup directory
    mkdir -p ${backups_path}/${backupname} && echo 'remote backup directory created'

    # create remote files backup
    tar cfpz ${backups_path}/${backupname}/${backupname}_files.tar.gz ${website_path} && echo 'remote files backup completed'

    # create remote database backup
    mysqldump -u ${db_user} -p'${db_password}' ${db_name} --result-file=${backups_path}/${backupname}/${backupname}_database.sql && echo 'remote database backup completed'
EOF


# create local backup directory
mkdir 'backups_'$1 && echo 'created local backup directory "backups_'$1'"'


# download remote files backup
scp $connection_details:$backups_path/$backupname/$backupname"_files.tar.gz" "backups_"$1"/"$backupname"_files.tar.gz" && echo downloaded remote files backup

# download remote database backup
scp $connection_details:$backups_path/$backupname/$backupname"_database.sql" "backups_"$1"/"$backupname"_database.sql" && echo downloaded remote database backup


ssh $connection_details << EOF
    set -xe

    # delete remote files backup
    rm $backups_path/$backupname/$backupname'_files.tar.gz' && echo 'deleted remote files backup'

    # delete remote database backup
    rm $backups_path/$backupname/$backupname'_database.sql' && echo 'deleted remote database backup'

    # delete remote backup directory
    rm -rf $backups_path/$backupname && echo 'deleted remote backup directory'

EOF
