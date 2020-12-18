# Configuration Management Systems - ict4tn022-3010


Exercises in the course:  
[h1 hello master-slave](https://hanu.org/ict4tn022-3010/h1-hello-master-slave.html)  
[h2 package file-server](https://hanu.org/ict4tn022-3010/h2_package_file-server.html)  
[h3 version control](https://hanu.org/ict4tn022-3010/h3-versionhallinta.html)  
[h4 timeline](https://hanu.org/ict4tn022-3010/h4-timeline.html)  
[h5 new command](https://hanu.org/ict4tn022-3010/h5-new-command.html)  
[h6 moottorix](https://hanu.org/ict4tn022-3010/h6-moottorix.html)  
[h7 own module part 1](https://hanu.org/ict4tn022-3010/h7-my_module.html)  
[h7 own module part 2](https://hanu.org/ict4tn022-3010/h7-nagios.html)  


## h5 new command


### Exercise a)

 Hei komento! Tee järjestelmään uusi "hei maailma" -komento ja asenna se orjille Saltilla. Liitä raporttiisi 'ls -l /usr/local/bin/' tulosteesta ainakin se rivi, jolla näkyy uuden komentotiedostosi oikeudet. Vinkkejä: tee shell script, joka tulostaa "hei maailma". Kokeile ensin käsin, sitten automatisoi. Luonteva paikka paketinhalllinnan ulkopuolelta asennetuille ohjelmille on /usr/local/bin/. Katso myös 'salt-call --local sys.state_doc file.managed'. Muista (aina ja kaikessa mitä teet tietokoneella) testata lopputulos. Hyvä testi on mahdollisimman lähellä sitä, mitä käyttäjä tekisi.

**Slave**:  

create the script:

`sudo vi /usr/local/bin/helloworld.sh`

with the following content:

```
#!/bin/sh
echo "Hello world!"
```

Give execute permissions to script:  
`sudo chmod 755 /usr/local/bin/helloworld.sh`

Verify the permissions with ls -la or stat commands:  
`ls -al /usr/local/bin/helloworld.sh`  
`stat /usr/local/bin/helloworld.sh`

The ls -la command outputs:  
`-rwxr-xr-x 1 root root 30 Dec  1 18:40 /usr/local/bin/helloworld.sh`

The stat command outputs the current permissions:  
`Access: (0755/-rwxr-xr-x)  Uid: (    0/    root)   Gid: (    0/    root)`

Execute the script: `/usr/local/bin/helloworld.sh`

The script outputs:  
`Hello world!`

Remove the script with command:  

sudo rm /usr/local/bin/helloworld.sh


**Master**:  
create folder structure for the helloworld script

`sudo mkdir -p /srv/salt/helloworld/files`

create the script:   

`sudo vi /srv/salt/helloworld/files/helloworld.sh`

with the same content as tested in slave:  
```
#!/bin/sh
echo "Hello world!"
```

create the init.sls file:  
`sudo vi /srv/salt/helloworld/init.sls`
with the content:  

```
# distribute the script
/usr/local/bin/helloworld.sh:
  file.managed:
    - source: salt://helloworld/files/helloworld.sh
    - user: root
    - group: root
    - mode: 755

```
Distribute the script with the command:  
`sudo salt '*' state.apply helloworld`

The script is distributed to the slave:  
```
ict4n022-slave:
----------
          ID: /usr/local/bin/helloworld.sh
    Function: file.managed
      Result: True
     Comment: File /usr/local/bin/helloworld.sh updated
     Started: 18:48:09.041060
    Duration: 59.554 ms
     Changes:   
              ----------
              diff:
                  New file
              mode:
                  0755

Summary for ict4n022-slave
------------
Succeeded: 1 (changed=1)
Failed:    0
------------
Total states run:     1
Total run time:  59.554 ms

```

**Slave**:  

Login to the slave and locate the script:

`ls -al /usr/local/bin/helloworld.sh`

`-rwxr-xr-x 1 root root 30 Dec  1 18:48 /usr/local/bin/helloworld.sh`

Run the script: `/usr/local/bin/helloworld.sh`

The script outputs: `Hello world!`


### Exercise b)
 whatsup.sh. Tee järjestelmään uusi komento, joka kertoo ajankohtaisia tietoja; asenna se orjille. Vinkkejä: Voit näyttää valintasi mukaan esimerkiksi päivämäärää, säätä, tietoja koneesta, verkon tilanteesta...

**Slave**:  

Create the script:
sudo vi /usr/local/bin/whatsup.sh


Include uptime, disk and memory free status and the IPv4 and IPv6 addresses:
```
#!/bin/sh
# Displays, how long the host has been running 
echo "The host" `hostname` "has been"  `uptime -p`
# Pause the script for one second
sleep 1s
# Create a empty line before next info
echo " "
# Display the disk free status of the system with human readable format 
# echo "Disk free status of the host:" `hostname`
# df -h |grep " \/$" |awk '{print "You have " $4 " free space on the volume",$1, "which is " $5 " of the filesystem."}'
df -h |grep " \/$" |awk -v hostname="$(hostname)" '{print "The host " hostname " has " $4 " free space on the volume",$1, "which is " $5 " of the filesystem."}'
# Pause the script for one second
sleep 1s
# Create a empty line before next info
echo " "
# Display amount of free and used memory of the system in mebibytes. 
# echo "Memory status of the host:" `hostname`
# free -m
#free -m |grep "^Mem" |awk -v hostname="$(hostname)" '{print "The host " hostname " has " $2 " megabytes total memory", "and " $4 " megabytes free memory"}' 
free -h |grep "^Mem" |awk -v hostname="$(hostname)" '{print "The host " hostname " has " $2 " total memory", "and " $7 " memory still available"}'
# Pause the script for one second
sleep 1s
# Create a empty line before next info
echo " "
# Display the ip-address of the host
echo "IPv4 address of the host" `hostname` "is" `ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
# Create a empty line before next info
echo " "
# Display the ip-address of the host
echo "IPv6 address of the host" `hostname` "is" `ip -6 addr|awk '{print $2}'|grep -P '^(?!fe80)[[:alnum:]]{4}:.*/64'|cut -d '/' -f1`
```

Give execute permissions to script:  
`sudo chmod 755 /usr/local/bin/whatsup.sh`

run the script

`/usr/local/bin/whatsup.sh` or by simply with command `whatsup.sh` as the script is in the default path.

The script returns: 

```
The host ict4n022-slave has been up 5 days, 7 hours, 57 minutes

The host ict4n022-slave has 9.1G free space on the volume /dev/sda2 which is 40% of the filesystem.
 
The host ict4n022-slave has 985M total memory and 64M memory still available
 
IPv4 address of the host ict4n022-slave is 192.168.10.56
 
IPv6 address of the host ict4n022-slave is 2001:14ba:SENCORED
```
After spending some minutes for these kind of scripts, it's recommended to copy the ready and tested script to master instead of creating it from the scratch.  

Remove the script from the slave:
`sudo rm /usr/local/bin/whatsup.sh`

**Master**:  

Create the directories for whatsup:  
`sudo mkdir -p /srv/salt/whatsup/files`

Create the script:  
`sudo vi /srv/salt/whatsup/files/whatsup.sh`

```
#!/bin/sh
# Displays, how long the host has been running 
echo "The host" `hostname` "has been"  `uptime -p`
# Pause the script for one second
sleep 1s
# Create a empty line before next info
echo " "
# Display the disk free status of the system with human readable format 
# echo "Disk free status of the host:" `hostname`
# df -h
#df -h |grep " \/$" |awk '{print "You have " $4 " free space on the volume",$1, "which is " $5 " of the filesystem."}'
df -h |grep " \/$" |awk -v hostname="$(hostname)" '{print "The host " hostname " has " $4 " free space on the volume",$1, "which is " $5 " of the filesystem."}'
# Pause the script for one second
sleep 1s
# Create a empty line before next info
echo " "
# Display amount of free and used memory of the system in mebibytes. 
# echo "Memory status of the host:" `hostname`
# free -m
#free -m |grep "^Mem" |awk -v hostname="$(hostname)" '{print "The host " hostname " has " $2 " megabytes total memory", "and " $4 " megabytes free memory"}' 
free -h |grep "^Mem" |awk -v hostname="$(hostname)" '{print "The host " hostname " has " $2 " total memory", "and " $7 " memory still available"}'
# Pause the script for one second
sleep 1s
# Create a empty line before next info
echo " "
# Display the ip-address of the host
echo "IPv4 address(es) of the host" `hostname` "is" `ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`
# Create a empty line before next info
echo " "
# Display the ip-address of the host
echo "IPv6 address(es) of the host" `hostname` "is" `ip -6 addr|awk '{print $2}'|grep -P '^(?!fe80)[[:alnum:]]{4}:.*/64'|cut -d '/' -f1`

```

create the init file:  
`sudo vi /srv/salt/whatsup/init.sls`  

with the content:  
```
# distribute the script
/usr/local/bin/whatsup.sh:
  file.managed:
    - source: salt://whatsup/files/whatsup.sh
    - user: root
    - group: root
    - mode: 755 
```
Distribute the file:
`sudo salt '*' state.apply whatsup`

```
ict4n022-slave:
----------
          ID: /usr/local/bin/whatsup.sh
    Function: file.managed
      Result: True
     Comment: File /usr/local/bin/whatsup.sh updated
     Started: 19:54:01.524636
    Duration: 127.19 ms
     Changes:   
              ----------
              diff:
                  New file
              mode:
                  0755

Summary for ict4n022-slave
------------
Succeeded: 1 (changed=1)
Failed:    0
------------
Total states run:     1
Total run time: 127.190 ms
```


**Slave**:  

Login to the slave and locate the script:

`ls -al /usr/local/bin/whatsup.sh`

`-rwxr-xr-x 1 root root 1065 Dec  1 19:54 /usr/local/bin/whatsup.sh`

Run the script: `whatsup.sh`

The script outputs:   

```
The host ict4n022-slave has been up 5 days, 8 hours, 14 minutes

The host ict4n022-slave has 9.1G free space on the volume /dev/sda2 which is 40% of the filesystem.
 
The host ict4n022-slave has 985M total memory and 64M memory still available
 
IPv4 address(es) of the host ict4n022-slave is 192.168.10.56
 
IPv6 address(es) of the host ict4n022-slave is 2001:14ba:CENSORED
```



### Exercise c)
 hello.py. Tee järjestelmään uusi komento Pythonilla ja asenna se orjille. Vinkkejä: Hei maailma riittää, mutta propellihatut saavat toki koodaillakin. Shebang on "#!/usr/bin/python3". Helpoin Python-komento on: print("Hei Tero!")

**Slave**:  

Create the script:  
`sudo vi /usr/local/bin/hello.py`

with the content:  
```
#!/usr/bin/python3
print("Hello world!")
```
Give execute permissions for the script:  
`sudo chmod 755 /usr/local/bin/hello.py`

`ls -la /usr/local/bin/hello.py`  
`-rwxr-xr-x 1 root root 41 Dec  1 20:07 /usr/local/bin/hello.py`

Run the script: `hello.py` which returns: `Hello world!`  

Delete script:  
`sudo rm /usr/local/bin/hello.py`


**Master**:  

create the directory structure:  
`sudo mkdir -p /srv/salt/hellopy/files`

`sudo vi /srv/salt/hellopy/files/hello.py`

with the content:  
```
#!/usr/bin/python3
print("Hello world!")
```

create the init file:  
`sudo vi /srv/salt/hellopy/init.sls`
with the content:  
```
# distribute the script
/usr/local/bin/hello.py:
  file.managed:
    - source: salt://hellopy/files/hello.py
    - user: root
    - group: root
    - mode: 755
```

Distribute the script with command:  
`sudo salt '*' state.apply hellopy`

```
ict4n022-slave:
----------
          ID: /usr/local/bin/hello.py
    Function: file.managed
      Result: True
     Comment: File /usr/local/bin/hello.py updated
     Started: 20:30:43.136169
    Duration: 359.472 ms
     Changes:   
              ----------
              diff:
                  New file
              mode:
                  0755

Summary for ict4n022-slave
------------
Succeeded: 1 (changed=1)
Failed:    0
------------
Total states run:     1
Total run time: 359.472 ms
```
**Slave**:  

Login to the slave and locate the script:  
`ls -al /usr/local/bin/hello.py`

`-rwxr-xr-x 1 root root 41 Dec  1 20:30 /usr/local/bin/hello.py`

Run the script with command `hello.py` which outputs:  
`Hello world!`

Extra task: 
Distribute an additional python script speedtest.py

Slave: download speedtest.py python script and store it /usr/local/bin directory:  
`sudo wget https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py -O /usr/local/bin/speedtest.py`

Give execute permissions: 

`chmod 755 /usr/local/bin/speedtest.py`

Run the script `speedtest.py`

```
Retrieving speedtest.net configuration...
Testing from DNA Oyj (CENCORED)...
Retrieving speedtest.net server list...
Selecting best server based on ping...
Hosted by Suomi Communications Oy (Espoo) [15.00 km]: 12.567 ms
Testing download speed................................................................................
Download: 824.38 Mbit/s
Testing upload speed....................................................................................................
Upload: 67.54 Mbit/s
```

Copy the script into master and delete the script:
`sudo rm /usr/local/bin/speedtest.py`

**Master**:  

create the directory structure for the speedtest app:  
`sudo mkdir -p /srv/salt/speedtest/files`

Copy the speedtest script into /srv/salt/speedtest/files directory.

Create the init file for the speedtest:  
`sudo vi /srv/salt/speedtest/init.sls`

with the content:  
```
# distribute the script
/usr/local/bin/speedtest.py:
  file.managed:
    - source: salt://speedtest/files/speedtest.py
    - user: root
    - group: root
    - mode: 755
```
Distribute the file with the command: `sudo salt '*' state.apply speedtest`

```
ict4n022-slave:
----------
          ID: /usr/local/bin/speedtest.py
    Function: file.managed
      Result: True
     Comment: File /usr/local/bin/speedtest.py updated
     Started: 20:40:51.910332
    Duration: 133.972 ms
     Changes:   
              ----------
              diff:
                  New file
              mode:
                  0755

Summary for ict4n022-slave
------------
Succeeded: 1 (changed=1)
Failed:    0
------------
Total states run:     1
Total run time: 133.972 ms
```
**Slave**:  

Login to the slave and locate the script:  
`ls -al /usr/local/bin/speedtest.py`

`-rwxr-xr-x 1 root root 65018 Dec  1 20:40 /usr/local/bin/speedtest.py`

Run the script with command `speedtest.py` which outputs:  
```  
Retrieving speedtest.net configuration...
Testing from DNA Oyj (CENSORED)...
Retrieving speedtest.net server list...
Selecting best server based on ping...
Hosted by Nebula Oy (Helsinki) [15.16 km]: 11.895 ms
Testing download speed................................................................................
Download: 622.00 Mbit/s
Testing upload speed................................................................................................
Upload: 76.91 Mbit/s
```
The script is working although the result differs form the previous but as the test server has changed and the server is virtual, there's no need to investigate further...



### Exercise d)
 Laiskaa skriptailua. Tee kansio, josta jokainen skripti kopioituu orjille. Vinkki: 'salt-call --local sys.state_doc file.recurse'. Kun tämä on valmis, on todella helppoa laittaa orjille mikä tahansa yhden tiedoston shell script, Python-ohjelma, Perl-ohjelma, Go-binääri tai muu yhden binäärin ohjelma.

**Slave**:  

Create three scripts:  

`sudo vi /usr/local/bin/show.ipv4.address.sh`

```
#!/bin/sh
# Display the ip-address of the host
echo "IPv4 address(es) of the host" `hostname` "is" `ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'`

```
`sudo vi /usr/local/bin/show.ipv6.address.sh`

```
#!/bin/sh
# Display the ip-address of the host
echo "IPv6 address(es) of the host" `hostname` "is" `ip -6 addr|awk '{print $2}'|grep -P '^(?!fe80)[[:alnum:]]{4}:.*/64'|cut -d '/' -f1` 
```

`sudo vi /usr/local/bin/show.uptime.sh`

```
#!/bin/sh
# Displays, how long the host has been running 
echo "The host" `hostname` "has been"  `uptime -p`
```

Give execute permissions for the scripts:  
`sudo chmod 755 /usr/local/bin/show*\.sh`

run the scripts:  
`for i in /usr/local/bin/show.*\.sh ; do $i ; done`

```
IPv4 address(es) of the host ict4n022-slave is 192.168.10.56
IPv6 address(es) of the host ict4n022-slave is 2001:14ba:CENSORED
The host ict4n022-slave has been up 5 days, 9 hours, 24 minutes
```

Copy the scripts to the master and delete the files locally:
`sudo rm /usr/local/bin/show.*\.sh`

Create the directory structure for the scripts:

`sudo mkdir -p /srv/salt/sysscripts/files`

```
# distribute files
/usr/local/bin/:
  file.recurse:
    - source: salt://sysscripts/files
    - dir_mode: 0775
    - file_mode: 0755
    - include_empty: True

```
Distribute the scripts with command:  `sudo salt '*' state.apply sysscripts`
```
The script files distributed succesfully:  
ict4n022-slave:
----------
          ID: /usr/local/bin/
    Function: file.recurse
      Result: True
     Comment: Recursively updated /usr/local/bin/
     Started: 21:12:56.618245
    Duration: 509.496 ms
     Changes:   
              ----------
              /usr/local/bin:
                  ----------
                  mode:
                      0775
              /usr/local/bin/show.ipv4.address.sh:
                  ----------
                  diff:
                      New file
                  mode:
                      0755
              /usr/local/bin/show.ipv6.address.sh:
                  ----------
                  diff:
                      New file
                  mode:
                      0755
              /usr/local/bin/show.uptime.sh:
                  ----------
                  diff:
                      New file
                  mode:
                      0755

Summary for ict4n022-slave
------------
Succeeded: 1 (changed=1)
Failed:    0
------------
Total states run:     1
Total run time: 509.496 ms

```
Slave:  
Locate the files:  
`for i in /usr/local/bin/show.*\.sh ; do ls -la $i ; done`

```
-rwxr-xr-x 1 root root 182 Dec  1 21:12 /usr/local/bin/show.ipv4.address.sh
-rwxr-xr-x 1 root root 175 Dec  1 21:12 /usr/local/bin/show.ipv6.address.sh
-rwxr-xr-x 1 root root 109 Dec  1 21:12 /usr/local/bin/show.uptime.sh
```

And run the scripts once again:  
`for i in /usr/local/bin/show.*\.sh ; do $i ; done`

```
IPv4 address(es) of the host ict4n022-slave is 192.168.10.56
IPv6 address(es) of the host ict4n022-slave is 2001:14ba:1ffe:1800:250:56ff:fea9:2c8a
The host ict4n022-slave has been up 5 days, 9 hours, 33 minutes
```


### Exercise e)
 Intel. Etsi kolme loppuprojektia joltain vanhalta kurssitoteutukselta. Kuvaile projektit tiiviisti ja linkitä alkuperäiseeen raporttin. Vinkkejä: Loppuprojekteja löydät etsimällä opiskelijoiden raportteja vanhoilta kursseilta ja selailemalla sivuja, joilta ne löytyivät. Raportteja löytyy vanhojen kurssitotetusten kommenteista. Ja tietysti kannattaa silmäillä listaa sieltä täältä, niin näet eri projektit kuin muut. Voi hakea myös Googlella ja DuckDuckGolla.


The assignment for this exercise was to find three final assignments for the previous courses and to describe the briefly and link sources for thie report:

**Project 1**: [Salted Teamspeak 3 Daemon](https://github.com/kristiansyrjanen/teamspeak3-salted)

The first report describes the distribution of Teamspeak 3 and is documented in the github.
The report start with installing the salt master and minions.

The actual local implementation and testing of the Teamspeak deployment manually is not documented in the  report ifself as it contains only top.sls structure of the Teamspeak deployment. However, more detailed description of the Teamspeak salt deployment can be found from the file V0.1.md. Also the complete set of directories and files required to deploy the Teamspeak 3 is stored in the github and available for testing. 

It would have been nice to have the steps and results of manual deployment of the Teamspeak 3 documented too. Luckily the high level steps for the manual deployment can be seen on the embedded partial content of the bash-script used for installing the Teamspeak manually.

 

**Project 2**: [Configuring several workstations with Salt](https://elisalinux.wordpress.com/2018/12/10/palvelinten-hallinta-loppuprojekti/)

The aim for this project was to deploy several virtual machines with Vagrant. After facing issues with the connectivity, the person was able to eploy several virtual machines with different operating systems. 

Next phases included 

- LAMP stack deployment
- LibreOffice, browser and antivirus deployment

These phases were mostly documented with screenshots but links for corresponding salt repositories stored in github was included in the project.

**Project 3**: [Deploy programs for irc and remote work](https://lahdemi.wordpress.com/2018/05/11/6-viikkotehtava-palvelinten-hallinta/)

This project was most complete of these three. Instead of using just screenshots, the final assignment was documented also well in written and the configuration files were also stored as text in the document.

Also the manual implementation and testing of the packages in the slave was documented before switching to Salt part.




### Exercise f)
 Lukua, ei luottamusta. Kokeile yhtä kohdassa d-Intel löytämääsi modulia koneella. Tämä on infraa koodina, joten luottamusta ei tarvita. Voit lukea koodista, mitä olet ajamassa.

I chose to test the LAMP stack used in the Project 2 and cloned the repository from the github and copied the corresponding directories and files in place.

`git clone https://github.com/elisapa/LAMP`

`sudo mkdir -p /srv/salt/LAMP`  

`sudo cp -r LAMP/* /srv/salt/LAMP/`  
`sudo rm -rf LAMP` 

I decided to remove one script and changed the password for the mysql client and extend the create commands with "if not exists" . 

`sudo rm /srv/salt/LAMP/script/salt-auto.sh`. 

`sudo vi /srv/salt/LAMP/commands.sql`

```
CREATE USER IF NOT EXISTS 'minion_lamp'@'localhost' IDENTIFIED BY 'CENSORE';
CREATE DATABASE IF NOT EXISTS lamp_database114;
GRANT USAGE ON lamp_database114.* TO 'minion_lamp' IDENTIFIED BY 'CENCORED';
```
Otherwise the set of files seemed to be pretty complete. However, the php version of the state file was referring to 7.0 and I checked the current repositories of the miion. The repositories on the minion were referring to version 7.2 so I decided to change the init.sls accordingly.

```
installation:
  pkg.installed:
    - pkgs:
      - apache2
      - mysql-server
      - mysql-client
      - php7.2
      - libapache2-mod-php7.2
      - php7.2-mysql
      - httpie

/etc/apache2/mods-enabled/userdir.conf:
  file.symlink:
   - target: ../mods-available/userdir.conf

/etc/apache2/mods-enabled/userdir.load:
  file.symlink:
   - target: ../mods-available/userdir.load

apache2service:
 service.running:
   - name: apache2
   - watch:
     - file: /etc/apache2/mods-enabled/userdir.conf
     - file: /etc/apache2/mods-enabled/userdir.load

/var/www/html/first-test.php:
  file.managed:
    - source: salt://LAMP/first-test.php

'http --headers localhost/first-test.php':
  cmd.run

/tmp/commands.sql:
  file.managed:
    - mode: 600
    - source: salt://LAMP/commands.sql

'cat /tmp/commands.sql|sudo mysql -u root':
  cmd.run:
    - unless: "echo 'show databases'|sudo mysql -u root|grep '^lamp$'"

```
sudo salt '*' state.apply LAMP

```
----------
          ID: cat /tmp/commands.sql|sudo mysql -u root
    Function: cmd.run
      Result: True
     Comment: Command "cat /tmp/commands.sql|sudo mysql -u root" run
     Started: 22:57:07.106958
    Duration: 579.255 ms
     Changes:   
              ----------
              pid:
                  4371
              retcode:
                  0
              stderr:
              stdout:

Summary for ict4n022-slave
------------
Succeeded: 8 (changed=8)
Failed:    0
------------
Total states run:     8
Total run time:  95.988 s

```
The testing of first-test.php (basically containing just `phpinfo();` ) page returns the php-info:  
`http http://localhost/first-test.php`

The mysql service is also running with empty LAMP database:  

```
mysql> use lamp_database114
Database changed
mysql> show tables;
Empty set (0.00 sec)

mysql> 
```

The fileset contained a sample userindex.html file which was not distributed into minion. 

Otherwise it was pretty easy to distribute the basic LAMP stack for minions with this bundle.