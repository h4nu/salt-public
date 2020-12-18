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

## h4 extra tasks

### Exercise a) 
Create a command and state file from it

slave:  
`sudo vi /usr/local/bin/extra1.sh`

```
#!/bin/sh
echo 'eka huuto'
```

run the command manually without changing file permissions: `sh /usr/local/bin/extra1.sh`

`eka huuto`

add execute permissions: `sudo chmod 755 /usr/local/bin/extra1.sh`

test command: `/usr/local/bin/extra1.sh`

`eka huuto`


master:

`sudo vi /srv/salt/extra1/extra1.sh`

```
#!/bin/sh
echo 'eka huuto'
```


`sudo mkdir -p /srv/salt/extra1`

`sudo vi /srv/salt/extra1/init.sls`

```
# distribute the script
/usr/local/bin/extra1.sh:
  file.managed:
    - source: salt://extra1/extra1.sh
    - user: root
    - group: root
    - mode: 755

# run the script
  cmd.run:
    - require:
      - file: /usr/local/bin/extra1.sh
```

Distribute the state and run the command on the slave:  
`sudo salt '*' state.apply extra1`

```
ct4n022-slave:
----------
          ID: /usr/local/bin/extra1.sh
    Function: file.managed
      Result: True
     Comment: File /usr/local/bin/extra1.sh updated
     Started: 12:33:45.670115
    Duration: 38.001 ms
     Changes:   
              ----------
              diff:
                  New file
              mode:
                  0755
----------
          ID: /usr/local/bin/extra1.sh
    Function: cmd.run
      Result: True
     Comment: Command "/usr/local/bin/extra1.sh" run
     Started: 12:33:45.709800
    Duration: 13.824 ms
     Changes:   
              ----------
              pid:
                  1977
              retcode:
                  0
              stderr:
              stdout:
                  eka huuto

Summary for ict4n022-slave
------------
Succeeded: 2 (changed=2)
Failed:    0
------------
Total states run:     2
Total run time:  51.825 ms
```


### Exercise b) 
Create a list of commands in a directory, distribute it and run the commands

`sudo mkdir -p /srv/salt/multi/test-cmds`

create scripts

`sudo vi /srv/salt/multi/test-cmds/eka.sh`

```
#!/bin/sh
echo eka
```

`sudo vi /srv/salt/multi/test-cmds/toka.sh`

```
#!/bin/sh
echo toka
```

`sudo vi /srv/salt/multi/test-cmds/kolmas.sh`

```
#!/bin/sh
echo kolmas
```

create the state file:

`sudo vi multi/init.sls` 

```
# distribute files
/usr/local/bin/test-cmds:
  file.recurse:
    - source: salt://multi/test-cmds
    - dir_mode: 0775
    - file_mode: 0755
    - include_empty: True

# run all at once:
run-parts --regex '^.*sh$' /usr/local/bin/test-cmds/:
  cmd.run

# run cmds one by one
run_eka:
  cmd.run:
    - name: /usr/local/bin/test-cmds/eka.sh

run_toka:
  cmd.run:
    - name: /usr/local/bin/test-cmds/toka.sh

run_kolmas:
  cmd.run:
    - name: /usr/local/bin/test-cmds/kolmas.sh
```

distribute the files and run the commands:

`sudo salt '*' state.apply multi`

```
----------
          ID: run-parts --regex '^.*sh$' /usr/local/bin/test-cmds/
    Function: cmd.run
      Result: True
     Comment: Command "run-parts --regex '^.*sh$' /usr/local/bin/test-cmds/" run
     Started: 13:20:45.559409
    Duration: 17.297 ms
     Changes:   
              ----------
              pid:
                  2378
              retcode:
                  0
              stderr:
              stdout:
                  eka
                  kolmas
                  toka
----------
          ID: run_eka
    Function: cmd.run
        Name: /usr/local/bin/test-cmds/eka.sh
      Result: True
     Comment: Command "/usr/local/bin/test-cmds/eka.sh" run
     Started: 13:20:45.577148
    Duration: 12.001 ms
     Changes:   
              ----------
              pid:
                  2383
              retcode:
                  0
              stderr:
              stdout:
                  eka
----------
          ID: run_toka
    Function: cmd.run
        Name: /usr/local/bin/test-cmds/toka.sh
      Result: True
     Comment: Command "/usr/local/bin/test-cmds/toka.sh" run
     Started: 13:20:45.589528
    Duration: 11.135 ms
     Changes:   
              ----------
              pid:
                  2385
              retcode:
                  0
              stderr:
              stdout:
                  toka
----------
          ID: run_kolmas
    Function: cmd.run
        Name: /usr/local/bin/test-cmds/kolmas.sh
      Result: True
     Comment: Command "/usr/local/bin/test-cmds/kolmas.sh" run
     Started: 13:20:45.601142
    Duration: 10.523 ms
     Changes:   
              ----------
              pid:
                  2387
              retcode:
                  0
              stderr:
              stdout:
                  kolmas

Summary for ict4n022-slave
------------
Succeeded: 5 (changed=4)
Failed:    0
------------
Total states run:     5
Total run time: 150.835 ms
```
