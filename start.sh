#!/bin/bash
# Name: one key start dockerized CLM
# Author: Eric, Jaden, Jeremy
# Date: 2016.03.22
# Description: start dockerized CLM per user's input.
# Usage: ./start.sh
# Change log:
# 2016-03-22: Initial project.
# 2016-03-22: Basic functions.
# 2016-04-11: Complete ports check.
# 2016-04-21: Complete app install, test on local machine passed.
# 2016-04-22: Check system memory.
# 2016-04-23: Add http download of docker images from 1207 server.
# 2016-04-25: Test on remote machine passed.
# 2016-05-04: Improve start.sh.
# 2016-05-12: Add create data warehouse (DW) tables.
# 2016-05-14: Plan to do jazzadmins map for test use, the choice can be made via asking [test] or [production]
# 2016-05-14: Plan to activate the trail licenses and deploy predefined PA templates for [test] use.
# 2016-05-14: Plan to add more apps choices.
# 2016-09-20: Adjust memory check, basic 6G, all apps 8G.
# Steps:
# 1. Check if docker engine is installed, check docker engine's compatibility with OS kernel if so, give advice if not.
# 2. Public URI (FQDN), check if the URI is resolvable and accessible.
# 3. Choose WAS architecture, All in one, or divided into multiple profiles.
# 4. Choose application, for all in one, just CLM; for multiple, JTS, DCC, JRS are default, then add CCM, RM or QM.
# 5. Pull images, run containers
# 6-1. Port conflict check/endurance/adjustment, in compose.yml, add 1 to the port numbers if the port is already in use.
# 6-2. DB2, create db per apps
# 7. WAS profile create & start
# *8. Security map (group, user, role, etc.)
# *9. JTS setup (command line, optional, user can do it via web)
# 10. WAS profile configuration
#  10.1 install CLM apps
#  10.2 Enable security (security.xml)
#  10.3 LDAP
#  10.4 Performance (JVM, etc.)
#  10.5 Environment (Sessions number, etc.)
#  *10.6 SSO (only need when multiple)
# 11. CLM, teamserver.properties
# 12. Restart WAS
# 13. Output result (SUCCESS or FAILED) access URL, etc.

# basepath=/scripts

was_version=8.5.5.8
clm_version=6.0.1
db2_version=10.5.0.7

was_image_id=fc2dc2ade386
clm_image_id=d401745d2323
db2_image_id=a492ed93e5da

was_tag_pre=dstcn/clmwas
clm_tag_pre=dstcn/clm
db2_tag_pre=dstcn/db2ese

db2_ssh_port=8022
was_ssh_port=9022
was_console_port=9043
was_app_port=9443

wasuser=wasadmin
waspass=wasadmin
dbuser=db2inst1
dbpass=db2inst1
ip=localhost

http_server=clmtest.abc.com

was_command="sshpass -p $waspass ssh -o "StrictHostKeyChecking=no" -p $was_ssh_port $wasuser@$ip"
db2_command="sshpass -p $dbpass ssh -o "StrictHostKeyChecking=no" -p $db2_ssh_port $dbuser@$ip"

work_dir=/tmp/CLM_Dockerization
download_dir=/tmp/tempimages

export LC_ALL=C
typeset -u OS=`uname`
  if [ "$OS" = "AIX" ]; then
    hostName=`hostname`
  fi
  if [ "$OS" = "LINUX" ]; then
    hostName=`hostname -f`
  fi

# install sshpass
which sshpass
if [ $? -eq 1 ]; then
cd /tmp
wget http://nchc.dl.sourceforge.net/project/sshpass/sshpass/1.05/sshpass-1.05.tar.gz
tar -xzvf sshpass-1.05.tar.gz
cd sshpass-1.05
./configure
make install
which sshpass
rm -rf /tmp/sshpass-1.05*
fi
# or
# docker pull vijayviji/sshpass
# alias sshpass="docker run --rm -v /var/run/docker.sock:/var/run/docker.sock vijayviji/sshpass sshpass"
#


install_default_apps()
{
  # default apps
  echo "Creating JTS, DCC, DW databases.."
  $db2_command "db2 create db jts using codeset UTF-8 territory en PAGESIZE 16384"
  $db2_command "db2 create db dcc using codeset UTF-8 territory en PAGESIZE 16384"
  $db2_command "db2 create db dw using codeset UTF-8 territory en PAGESIZE 16384"

  echo "Waiting for WAS to be started.."
  sleep 120
  # ping 9043

  # jts
  $was_command "echo \"com.ibm.team.repository.server.repourl.hostname=$public_uri\" >> /opt/IBM/JazzTeamServer601/server/conf/jts/teamserver.properties;echo 'com.ibm.team.repository.ldap.registryLocation=ldaps\://bluepages.ibm.com 636' >> /opt/IBM/JazzTeamServer601/server/conf/jts/teamserver.properties;echo 'com.ibm.team.repository.ldap.baseGroupDN=ou\=memberList,ou\=ibmGroups,o\=ibm.com' >> /opt/IBM/JazzTeamServer601/server/conf/jts/teamserver.properties;echo 'com.ibm.team.repository.ldap.findGroupsForUserQuery=uniquemember\={USER-DN}' >> /opt/IBM/JazzTeamServer601/server/conf/jts/teamserver.properties;echo 'com.ibm.team.repository.ldap.membersOfGroup=uniquemember' >> /opt/IBM/JazzTeamServer601/server/conf/jts/teamserver.properties;echo 'com.ibm.team.repository.ldap.userAttributesMapping=userId\=preferredidentity,name\=cn,emailAddress\=mail' >> /opt/IBM/JazzTeamServer601/server/conf/jts/teamserver.properties;echo 'com.ibm.team.repository.ldap.baseUserDN=ou\=bluepages,o\=ibm.com' >> /opt/IBM/JazzTeamServer601/server/conf/jts/teamserver.properties;/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -user jeremy@abc.com -password pass4jeremy -f /scripts/install_jts_app.py"

  # dcc
  $was_command "echo \"com.ibm.team.repository.server.repourl.hostname=$public_uri\" >> /opt/IBM/JazzTeamServer601/server/conf/dcc/teamserver.properties;/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -user jeremy@abc.com -password pass4jeremy -f /scripts/install_dcc_app.py"

  # jrs
  # $was_command "echo \"com.ibm.team.repository.server.repourl.hostname=$public_uri\" >> /opt/IBM/JazzTeamServer601/server/conf/rs/teamserver.properties;/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -user jeremy@abc.com -password pass4jeremy -f /scripts/install_rs_app.py"

}

install_extra_apps()
{
  # extra apps
  if [[ "${apps_to_install[@]}" =~ "CCM" ]] || [[ "${apps_to_install[@]}" =~ "RM" ]] || [[ "${apps_to_install[@]}" =~ "QM" ]]; then
  for app_to_install in ${apps_to_install[@]};
  do
    install_app_s $app_to_install
  done
  else
    echo 'Please enter any of the CCM, RM or QM.'
    install_extra_apps;
  fi
}

restart_was()
{
  # $was_command "/scripts/restart-was.sh"
  # docker stop single_clm
  # docker start single_clm
  stop_was;
  start_was;
}

stop_was(){
  $was_command "/scripts/stop-was.sh"
}
start_was(){
  $was_command "/opt/IBM/WebSphere/AppServer/profiles/CLM/bin/startServer.sh server1"
  # $was_command "/scripts/start_was.sh"
}
check_status()
{
  $was_command "/scripts/check-was.sh"
  $db2_command "db2 list db directory"
  # sshpass -p db2inst1 ssh -p $db2_ssh_port db2inst1@localhost "/scripts/check-db.sh"

}

map_security()
{
  for app_security in JTS CCM RM;
  do
    if [ "$app_security" = "JTS" ]; then
    $was_command "/scripts/security_jts.sh"

  elif [ "$app_security" = "CCM" ]; then
  $was_command "/scripts/security_ccm.sh"

  elif [ "$app_security" = "RM" ]; then
  $was_command "/scripts/security_rm.sh"

  fi
  done
  #bluepages
  #$was_command "/scripts/bluepages_cert.sh"

  #for JTS, this part can be added to entrypoint.sh
}

checkIfWasIsReady(){
  echo "Checking if WAS profile is created and started.."
  ps -ef|grep java|grep AppServer
  if [ $? -eq 0 ]; then
    echo "WAS is ready!"
  else
    sleep 10
    checkIfWasIsReady
  fi
}

install_app_s(){
  # extra apps
  # app=typeset -l $1
  # app=`echo $1|tr A-Z a-z`
  app=$1

  if [ "$app" = "CCM" ]; then
  # ccm & clmhelp
  $was_command "echo \"com.ibm.team.repository.server.repourl.hostname=$public_uri\" >> /opt/IBM/JazzTeamServer601/server/conf/ccm/teamserver.properties;/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -user jeremy@abc.com -password pass4jeremy -f /scripts/install_ccm_app.py"
  echo "Creating CCM database.."
  $db2_command "db2 create db ccm using codeset UTF-8 territory en PAGESIZE 16384"

elif [ "$app" = "QM" ]; then
  $was_command "echo \"com.ibm.team.repository.server.repourl.hostname=$public_uri\" >> /opt/IBM/JazzTeamServer601/server/conf/qm/teamserver.properties;/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -user jeremy@abc.com -password pass4jeremy -f /scripts/install_qm_app.py"
  echo "Creating QM database.."
  $db2_command "db2 create db qm using codeset UTF-8 territory en PAGESIZE 16384"

elif [ "$app" = "RM" ]; then
  # rm & converter
  $was_command "echo \"com.ibm.team.repository.server.repourl.hostname=$public_uri\" >> /opt/IBM/JazzTeamServer601/server/conf/rm/teamserver.properties;/opt/IBM/WebSphere/AppServer/bin/wsadmin.sh -lang jython -user jeremy@abc.com -password pass4jeremy -f /scripts/install_rm_app.py"
  echo "Creating RM database.."
  $db2_command "db2 create db rm using codeset UTF-8 territory en PAGESIZE 16384"

fi

}

createTables(){
  # extra apps
  # app=typeset -l $1
  # app=`echo $1|tr A-Z a-z`
  app=$1

  if [ "$app" = "CCM" ]; then
  $was_command "cd /opt/IBM/JazzTeamServer601/server;/opt/IBM/JazzTeamServer601/server/repotools-ccm.sh -createTables teamserver.properties=/opt/IBM/JazzTeamServer601/server/conf/ccm/teamserver.properties"

elif [ "$app" = "QM" ]; then
  $was_command "cd /opt/IBM/JazzTeamServer601/server;/opt/IBM/JazzTeamServer601/server/repotools-qm.sh -createTables teamserver.properties=/opt/IBM/JazzTeamServer601/server/conf/qm/teamserver.properties"

elif [ "$app" = "RM" ]; then
  $was_command "cd /opt/IBM/JazzTeamServer601/server;/opt/IBM/JazzTeamServer601/server/repotools-rm.sh -createTables teamserver.properties=/opt/IBM/JazzTeamServer601/server/conf/rm/teamserver.properties"

fi

}

install_app_m()
{
  echo "in-progress"
}

test_ip()
{
  ping -c 1 $1
  if [ $? -eq 0 ]; then
    echo "Public URI recorded!"
  else
    echo "Please enter a valid public URI, make sure the server is up."
    read public_uri
    test_ip $1
  fi
}

check_sshd(){
  ps -ef|grep sshd|grep -v grep
  if [ $? -eq 0 ]; then
    echo "sshd service is up."
  else
    sleep 10
    check_sshd
  fi
}

test_ssh()
{
  # alternative, <ssh -oStrictHostKeyChecking=no> or <ssh -o "StrictHostKeyChecking=no">
  echo "checking if sshd service is up.."
  sleep 60
  $was_command echo "hello WAS"
  $db2_command echo "hello DB2"
}

download_images(){
  echo "Checking if images are existing.."
  mkdir -p $download_dir
  cd $download_dir
  docker images|grep "$clm_tag_pre"|grep -v grep| grep -v was
  if [ $? -eq 0 ]; then
    echo "clm image exists."
  else
    # sftp -P 2222 ftp1@lexbz1207.lexington.ibm.com:/images/clm.tar /tmp
    which wget
    if [ $? -eq 0 ]; then
    wget http://$http_server:8080/clm.tar
  else
    curl -LO http://$http_server:8080/clm.tar
  fi
    docker load < $download_dir/clm.tar
    docker tag $clm_image_id $clm_tag_pre:$clm_version
    rm -f $download_dir/clm.tar
  fi
  docker images|grep "$was_tag_pre"|grep -v grep
  if [ $? -eq 0 ]; then
    echo "clmwas image exists."
  else
    # sftp -P 2222 ftp1@lexbz1207.lexington.ibm.com:/images/clmwas.tar /tmp
    which wget
    if [ $? -eq 0 ]; then
    wget http://$http_server:8080/clmwas.tar
  else
    curl -LO http://$http_server:8080/clmwas.tar
  fi
    docker load < $download_dir/clmwas.tar
    docker tag $was_image_id $was_tag_pre:$was_version
    rm -f $download_dir/clmwas.tar
  fi
  docker images|grep "$db2_tag_pre"|grep -v grep
  if [ $? -eq 0 ]; then
    echo "db2 image exists."
  else
    # sftp -P 2222 ftp1@lexbz1207.lexington.ibm.com:/images/db2ese.tar /tmp
    which wget
    if [ $? -eq 0 ]; then
    wget http://$http_server:8080/db2ese.tar
  else
    curl -LO http://$http_server:8080/db2ese.tar
  fi
    docker load < $download_dir/db2ese.tar
    docker tag $db2_image_id $db2_tag_pre:$db2_version
    rm -f $download_dir/db2ese.tar
  fi
  cd $work_dir
  rm -rf $download_dir
}

check_ports()
{
  for((i=2;i<17;i++));
  do
  netstat -na|grep ":$[ 9020 + ${i} ] "
  if [ $? -eq 0 ]; then
    echo "port $[ 9020 + ${i} ] already be used, use $[ 9021 + ${i} ] instead."
    was_ssh_port=$[ 9020 + ${i+1} ]
  else
    was_ssh_port=$[ 9020 + ${i} ]
    break
  fi
  done
  for((j=3;j<17;j++));
  do
  netstat -na|grep ":$[ 9040 + ${j} ] "
  if [ $? -eq 0 ]; then
    echo "port $[ 9040 + ${j} ] already be used, use $[ 9041 + ${j} ] instead."
    was_console_port=$[ 9040 + ${j+1} ]
  else
    was_console_port=$[ 9040 + ${j} ]
    break
  fi
  done
  for((k=3;k<17;k++));
  do
  netstat -na|grep ":$[ 9440 + ${k} ] "
  if [ $? -eq 0 ]; then
    echo "port $[ 9440 + ${k} ] already be used, use $[ 9441 + ${k} ] instead."
    was_app_port=$[ 9441 + ${k} ]
  else
    was_app_port=$[ 9440 + ${k} ]
    break
  fi
  done
  for((l=2;l<17;l++));
  do
  netstat -na|grep ":$[ 8020 + ${l} ] "
  if [ $? -eq 0 ]; then
    echo "port $[ 8020 + ${l} ] already be used, use $[ 8021 + ${l} ] instead."
    db2_ssh_port=$[ 8021 + ${l} ]
  else
    db2_ssh_port=$[ 8020 + ${l} ]
    break
  fi
  done
}

add_publicuri_to_teamserver(){
  echo "com.ibm.team.repository.server.repourl.hostname=$uri" >> /opt/IBM/JazzTeamServer601/server/conf/$app/teamserver.properties
  # echo "com.ibm.team.repository.server.repourl.hostname=$public_uri" >> /opt/IBM/JazzTeamServer601/server/conf/{jts,ccm,dcc,gc,qm,relm,rm}/teamserver.properties
}

main()
{
  # 1
echo "Checking if docker engine is installed and compatible for use.."
which docker
if [ $? -eq 0 ]; then
  echo "docker engine installed."
  docker version
  docker info
  uname -r
else
  echo "docker engine not found, you must have a Docker engine available. If you do not have Docker see docs.docker.com to get started."
fi

echo "Checking if OS has enough memory.."
free -m
total_memory=`vmstat -s | grep "total memory" | awk '{print $1}'`
total_swap=`vmstat -s | grep "total swap" | awk '{print $1}'`
free_memory=`vmstat -s | grep "free memory" | awk '{print $1}'`
free_swap=`vmstat -s | grep "free swap" | awk '{print $1}'`

if [ $[ $total_memory + $total_swap ] -gt 7000000 ] && [ $[ $free_memory + $free_swap ] -gt 4000000 ]; then
  echo "Free memory meet requirements, you can continue."
else
  echo "Memory or free memory not enough (less than 4 GB), quiting.."
  exit 99
fi

echo "Checking if file system has enough space.."
if [ "$OS" = "LINUX" ]; then
  free_disk1=`df /|awk '{print $4}'|tail -1`
  if [ $free_disk1 -gt 40000000 ]; then
    free_disk2=`df /tmp|awk '{print $4}'|tail -1`
    if [ $free_disk2 -gt 4000000 ]; then
      echo "Free disk space meet requirements, you can continue."
    else
      echo "Disk space on /tmp is not enough (less than 4 GB), quiting.."
      exit 99
    fi
  else
    echo "Disk space on / not enough (less than 40 GB), quiting.."
    exit 99
  fi
fi

mkdir -p $work_dir
# mkdir -p /var/data/{WAS_profiles,CLM,DB2}
# chmod -R 777 /var/data

download_images;
which docker-compose
if [ $? -eq 0 ]; then
  echo "docker-compose is installed"
else
  curl -L https://github.com/docker/compose/releases/download/1.7.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
fi

# 2
echo "Please enter the alias of the host as public URI you want to use."
echo "An example of a good fully qualified hostname is clmwb.example.com, default value: [$hostName]"
read public_uri1
if [ -z $public_uri1 ]; then
  public_uri1=$hostName
fi
# test $public_uri
test_ip $public_uri1
export public_uri=$public_uri1

# 3
echo "Please choose the type of WAS profiles you want to create, [single] or [multiple], default value [single]"
read was_architecture
echo "Please choose the apps you want to run, [CCM], [RM], and/or [QM], separated by space."
read apps_to_install

if [ -z $was_architecture ]; then
  was_architecture=single
fi
if [ "$was_architecture" = "multiple" ]; then
  echo "You chose multiple WAS profiles, one app one profile in one WAS container!"
  # mkdir -p /data/db2{home,dump}
  # chmod 777 /data/db2{home,dump}
  # 6-1
  cd $work_dir
  check_ports;
  # 5
(cat <<EOF
wasclm:
    image: "dstcn/clmwas:${was_version}"
    hostname: clm
    ports:
        - "${was_ssh_port}:22"
        - "${was_console_port}:9043"
        - "${was_app_port}:9443"
    links:
        - db:database
    volumes_from:
        - clm
    restart: always
    container_name: base_clm

db:
    image: "dstcn/db2ese:${db2_version}"
    privileged: true
    expose:
        - "50000"
    ports:
        - "${db2_ssh_port}:22"
    restart: always
    container_name: clmdb

clm:
    image: "dstcn/clm:${clm_version}"
    container_name: clm_clm
    restart: always
EOF
) >docker-compose-multiple.yml

count_n=1
for app_to_install in ${apps_to_install[@]};
do
(cat <<EOF
${app_to_install}:
    image: "dstcn/wasbase:${was_version}"
    hostname: ${app_to_install}
    ports:
        - "$[ ${was_ssh_port} + ${count_n} ]:22"
        - "$[ ${was_console_port} + ${count_n} ]:9043"
        - "$[ ${was_app_port} + ${count_n} ]:9443"
    links:
        - db:database
    volumes_from:
        - clm
    restart: always
    container_name: ${app_to_install}_${app_to_install}
EOF
) >>docker-compose-multiple.yml
((count_n++))
done

docker-compose -f docker-compose-multiple.yml up -d
test_ssh;

  # default apps
install_default_apps;

install_app_m $app_to_install


elif [ "$was_architecture" = "single" ]; then
  echo "You chose single WAS profile, all in one!"
  # mkdir -p /data/db2{home,dump}
  # chmod 777 /data/db2{home,dump}
  # 6-1
  check_ports;
  # 5
(cat <<EOF
wasclm:
  image: "dstcn/clmwas:${was_version}"
  hostname: clm
  ports:
    - "${was_ssh_port}:22"
    - "${was_console_port}:9043"
    - "${was_app_port}:9443"
  links:
      - db:database
  volumes_from:
      - clm
  restart: always
  container_name: single_clm

db:
  image: "dstcn/db2ese:${db2_version}"
  privileged: true
  expose:
      - "50000"
  ports:
      - "${db2_ssh_port}:22"
  restart: always
  container_name: clmdb

clm:
  image: "dstcn/clm:${clm_version}"
  container_name: clm_clm
  restart: always
EOF
) >docker-compose-single.yml

  docker-compose -f docker-compose-single.yml up -d

test_ssh;

# default apps
install_default_apps;

  # 4

  install_extra_apps;



# 7
# will be done via entrypoint.sh when build from WAS folder

# 8 10.2
#map_security;

# 9
# /opt/IBM/JazzTeamServer601/server/repotools-jts.sh -setup repositoryURL=https://$public_uri:9443/jts adminUserID=ADMIN adminPassword=ADMIN

# 12
# restart_was;
stop_was;


echo "Creating tables..."
$was_command "cd /opt/IBM/JazzTeamServer601/server;/opt/IBM/JazzTeamServer601/server/repotools-jts.sh -createTables teamserver.properties=/opt/IBM/JazzTeamServer601/server/conf/jts/teamserver.properties"
$was_command "cd /opt/IBM/JazzTeamServer601/server;/opt/IBM/JazzTeamServer601/server/repotools-jts.sh -createWarehouse teamserver.properties=/opt/IBM/JazzTeamServer601/server/conf/jts/teamserver.properties"
$was_command "cd /opt/IBM/JazzTeamServer601/server;/opt/IBM/JazzTeamServer601/server/repotools-dcc.sh -createTables teamserver.properties=/opt/IBM/JazzTeamServer601/server/conf/dcc/teamserver.properties"

# $was_command "cd /opt/IBM/JazzTeamServer601/server;/opt/IBM/JazzTeamServer601/server/repotools-jts.sh -createTables teamserver.properties=/opt/IBM/JazzTeamServer601/server/conf/jts/teamserver.properties;/opt/IBM/JazzTeamServer601/server/repotools-ccm.sh -createTables teamserver.properties=/opt/IBM/JazzTeamServer601/server/conf/ccm/teamserver.properties;/opt/IBM/JazzTeamServer601/server/repotools-qm.sh -createTables teamserver.properties=/opt/IBM/JazzTeamServer601/server/conf/qm/teamserver.properties;/opt/IBM/JazzTeamServer601/server/repotools-rm.sh -createTables teamserver.properties=/opt/IBM/JazzTeamServer601/server/conf/rm/teamserver.properties;/opt/IBM/JazzTeamServer601/server/repotools-dcc.sh -createTables teamserver.properties=/opt/IBM/JazzTeamServer601/server/conf/dcc/teamserver.properties"
# if [[ "${apps_to_install[@]}" =~ "CCM" ]] || [[ "${apps_to_install[@]}" =~ "RM" ]] || [[ "${apps_to_install[@]}" =~ "QM" ]]; then
for app_to_install in ${apps_to_install[@]};
do
  createTables $app_to_install
done
# fi

# 13
echo "Waiting for WAS to be restarted, this may take a while.."
start_was;
check_status;

echo "WAS console: https://$public_uri:$was_console_port/ibm/console"
echo "You may need to map security groups/users first, then do jts setup at"
echo "https://$public_uri:$was_app_port/jts/setup"
echo "Enjoy! `date`"
#
else
  echo 'Please enter "single" or "multile".'
  main;
fi
}

main;
