#!/bin/bash
# Program:
#   This program is create for linux server administrator to backup
#   data which include service configuration, mysql raw data, and web project etc.
# Principle:
#   The data that should be backup will be packaged by this script use tar command and will be saved under /tmp.
#   The next step is copy backup data from /tmp to nfs share directGetting the first field and fourth field of Server ip address and save in HOST parameter.ory, which is designed to backup data saving under the remote backup server.
# History：
#   2015.03.28  Frist release by CarlZhong
#   2015.03.30  Second release by CarlZhong
###############################################################################################################
#!/bin/bash
#Parameters Description
#Obtaining current time and saving in DATE parameter.
DATE=$(date +%y%m%d)
#Obtaining the first field and fourth field of Server ip address and saving in HOST parameter.
HOST=$(ifconfig | awk -F ":" '/addr:1[79]/{print $2}' | sed 's/\..*\..*\./ /g' | awk -F " " '{if(NR==1) printf("%s.%s\n",$1,$2)}')
#Creating the prefix of backup files saving in PREFIX parameter.
PREFIX=$HOST-$DATE
#$BKPDIR is the directory which will be used to saving backup files.
BKPDIR="/tmp/backup/"
#$NFSDIR is the directory which will be mount nfs.
NFSDIR="/nfsdir"

#Function Description
#camNFS implement to mount NFS and check the NFS which is mount in system.
function camNFS()
{
    /bin/mount -t nfs 192.168.0.142:/tmp/nfsshare $NFSDIR 1>/dev/null 2>&1
    LOG $? 1
    /bin/mount -l | /bin/grep "192.168.0.142:/tmp/nfsshare" 1>/dev/null 2>&1
    LOG $? 1
}

function BackupData()
{
    /bin/tar -zcvf $BKPDIR$PREFIX.etc.tar.gz /etc 1>/dev/null 2>&1
    LOG $? 2
    /usr/local/mysql/bin/mysqldump -u root -p123456 --all-databases >$BKPDIR$PREFIX.mysqld.sql 1>/dev/null 2>&1
    LOG $? 2
}

function CleanUp()
{
   rm -fr /tmp/backup/* 1>/dev/null 2>&1
}

#This function will write error log.
function LOG()
{
  if [ "$1" -ne 0 ]
  then
      case $2 in
        1)
            echo "error mount: The remote directory is not mount in this system!!!"
            exit 1;;
        2)
            echo "BackupError: Couldn't backup data maybe permission dennis or disk is full"
        CleanUp
            exit 2;;
    3)
        echo "TransistError: Backup data couldn't be copyed to $NFSDIR"
        rm -f $PREFIX.*
            /bin/umount $NFSDIR
        exit 3;;
      esac
  fi
}

if [ ! -d $BKPDIR ]
then
        mkdir $BKPDIR 1>/dev/null 2>&1
        echo "backup: Create $BKPDIR directory"
fi
if [ ! -d $NFSDIR ]
then
        mkdir $NFSDIR 1>/dev/null 2>&1
        echo "backup: Create $NFSDIR directory"
fi

#Main
CleanUp
BackupData
camNFS
rm -fr $NFSDIR/$HOST-.*
sudo -u#505 cp -a $BKPDIR* $NFSDIR
LOG $? 3
echo "Backup data had been copyed (successfully!!!!)"
/bin/umount $NFSDIR
CleanUp
exit 0
