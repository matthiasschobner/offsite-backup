#!/bin/bash

set -e # Exit script on error

##
# Styled echo
# @param $1 text
echo_styled()
{
    Yellow='\x1B[;33m'
    ResetColor='\x1B[0m'
	echo "${Yellow}${1}${ResetColor}"
}


# Output program information
version="2.0.0"
author_1="Daniel Ruf (https://daniel-ruf.de))"
author_2="Matthias Schobner (https://schobner.rocks)"
echo_styled "Website backup ${version} by ${author_1} & ${author_2}"


# Pass config file to this script. Example: sh backup.sh my_website.config
CONFIG_FILE=$( dirname "${BASH_SOURCE[0]}" )/$1
echo_styled "Read config file: ${CONFIG_FILE}"
# shellcheck disable=SC1090
source "${CONFIG_FILE}"


# Config
tar_filename="$(date +"%Y_%m_%d_%H_%M_%S")_files.tar.gz"
sql_filename="$(date +"%Y_%m_%d_%H_%M_%S")_database.sql"
local_backups_path="./backups/${1%.config}"


# Set ssh connection details
# shellcheck disable=SC2154
if [ -n "${ssh_config}" ]; then
    ssh_connection=$ssh_config
else
    ssh_connection=$ssh_user@$ssh_host
fi
echo_styled 'SSH connection configured.'


# Set mysql connection details
echo_styled 'Validate if MySQL configuration is set.'
if [ -n "${db_host}" ] && [ -n "${db_user}" ] && [ -n "${db_password}" ] && [ -n "${db_name}" ]; then
    mysql_connection="-h ${db_host} -u ${db_user} -p'${db_password}' ${db_name}"
    echo_styled 'MySQL connection configured.'
fi


# Run backup
if [ -z "${server_website_path}" ]; then
    echo 'Config parameter server_website_path is missing'
    exit
fi
if [ -z "${server_backups_path}" ]; then
    echo 'Config parameter server_backups_path is missing'
    exit
fi
echo_styled 'Connect to server for run backup.'
# shellcheck disable=SC2087
# shellcheck disable=SC2154
ssh "${ssh_connection}" << EOF
    mkdir -p ${server_backups_path}
    echo 'Remote backup directory created.'

    rm -rfv ${server_backups_path}/*
    echo 'Remote backup directory cleaned up.'

    tar cfpz ${server_backups_path}/${tar_filename} ${server_website_path} ${server_website_path_exclude} --checkpoint=1000
    echo 'Remote files backup completed.'

    if [ -n "${mysql_connection}" ]; then mysqldump ${mysql_connection} --result-file=${server_backups_path}/${sql_filename}; fi
    if [ -n "${mysql_connection}" ]; then echo 'Remote database backup completed.'; fi
EOF
echo_styled 'Remote backup is ready.'


# Create local backup directory
echo_styled "Create local backup directory: '${local_backups_path}'"
mkdir -p "${local_backups_path}"
echo_styled "Local backup directory created."


# Download remote files
echo_styled 'Connect to server to download the files backup.'
scp "${ssh_connection}:${server_backups_path}/${tar_filename}" "${local_backups_path}/${tar_filename}"
echo_styled 'Downloaded remote files backup.'
if [ -n "${mysql_connection}" ]; then
    echo_styled 'Connect to server to download the database backup.'
    scp "${ssh_connection}:${server_backups_path}/${sql_filename}" "${local_backups_path}/${sql_filename}"
    echo_styled 'Downloaded remote database backup.'
fi


# Remove old files
echo_styled 'Connect to server to cleanup backup folder.'
# shellcheck disable=SC2087
ssh "${ssh_connection}" << EOF
    rm ${server_backups_path}/${tar_filename}
    echo 'Remote files backup deleted.'

    if [ -n "${mysql_connection}" ]; then rm ${server_backups_path}/${sql_filename}; fi
    if [ -n "${mysql_connection}" ]; echo 'Remote database backup deleted.'; fi

    rm -rfv ${server_backups_path}/*
    echo 'Remote backup directory cleaned up.'
EOF
echo_styled 'Remote backup directory cleaned up.'
