# offsite-backup
scripts (bash) to create an offsite backup of a website (database and files) over SSH


## config
Copy ```project_name.config.example```.
Replace "project_name" with the name of your project.  
E.g.:
```bash
$ cp project_name.config.example my_website.config
```
And customize the file.
```bash
$ vim my_website.config
```


### config – ssh connection
To connect the server without password, config your local ssh key and add your public key to the server.

More Infos:  
https://wiki.ubuntuusers.de/SSH/#Authentifizierung-ueber-Public-Keys  

Setup .ssh/config  
More Infos:  
https://wiki.ubuntuusers.de/SSH/#ssh-config  

## run backup
Run the script with the project name as parameter.  
Watch closely for the project name! E.g.:
```bash
$ sh backup.sh my_website
```
for my_website.config
