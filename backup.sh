#!/bin/bash


# Output program information
version="1.2.0"
date="17.05.2019"
author_1="Daniel Ruf (https://daniel-ruf.de))"
author_2="Matthias Schobner (https://www.schobner.rocks)"
echo_styled "Website backup ${version} (${date}) by ${author_1} & ${author_2}"


##
# Styled echo
# @param $1 text
echo_styled()
{
    Yellow='\x1B[;33m'
    ResetColor='\x1B[0m'
	echo ${Yellow}${1}${ResetColor}
}


# Pass config file to this script. Example: sh backup.sh my_website
CONFIG_FILE=$( dirname "${BASH_SOURCE[0]}" )/$1".config"
echo_styled "Read config file: ${CONFIG_FILE}"
source ${CONFIG_FILE}


# Config
tar_filename="$(date +"%Y_%m_%d_%H_%M_%S")_files.tar.gz"
sql_filename="$(date +"%Y_%m_%d_%H_%M_%S")_database.sql"
local_path="backups_${1}"


# Set ssh connection details
if [ -z "$ssh_config" ]; then
    ssh_connection="$ssh_user@$ssh_host"
else
    ssh_connection=${ssh_config}
fi
echo_styled "SSH connection configured."


# Set mysql connection details
mysql_connection="-h ${db_host} -u ${db_user} -p'${db_password}' ${db_name}"
echo_styled "MySQL connection configured."


# Run backup
echo_styled "Connect to server for run backup."
ssh ${ssh_connection} << EOF
    mkdir -p ${backups_path}
    echo 'Remote backup directory created.'

    rm -rfv ${backups_path}*
    echo 'Remote backup directory cleaned up.'

    tar cfpz ${backups_path}${tar_filename} ${website_path}
    echo 'Remote files backup completed.'

    mysqldump ${mysql_connection} --result-file=${backups_path}${sql_filename}
    echo 'Remote database backup completed.'
EOF


# Create local backup directory
mkdir "${local_path}"
echo_styled "Created local backup directory: '${local_path}'"


# Download remote files
echo_styled "Connect to server to download the files backup."
scp ${ssh_connection}:${backups_path}${tar_filename} "${local_path}/${tar_filename}"
echo_styled 'Downloaded remote files backup.'
echo_styled "Connect to server to download the database backup."
scp ${ssh_connection}:${backups_path}${sql_filename} "${local_path}/${sql_filename}"
echo_styled 'Downloaded remote database backup.'


# Remove old files
echo_styled "Connect to server to cleanup backup folder."
ssh ${ssh_connection} << EOF
    rm ${backups_path}${tar_filename}
    echo 'Remote files backup deleted.'

    rm ${backups_path}${sql_filename}
    echo 'Remote database backup deleted.'

    rm -rfv ${backups_path}*
    echo 'Remote backup directory cleaned up.'
EOF

echo_styled 'Remote backup directory cleaned up.'
