#!/bin/bash

mkdir backups_server_gn-staging
rsync -av gn-staging:backups/* backups_server_gn-staging

mkdir backups_server_gn-live
rsync -av gn-live:backups/* backups_server_gn-live

mkdir backups_server_bm-staging
rsync -av gn-staging:backups/* backups_server_bm-staging

mkdir backups_server_bm-live
rsync -av gn-live:backups/* backups_server_bm-live
