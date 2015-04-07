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
#   2015.04.07  3th release by CarlZhong
# Log:
#   To improve initialization module.
#   To improve Log function.
#   To add more comment.
# Attention:
#   if you copy or download this file in you Unix or GNU/Linux that you must execute follow down command to make script work.
#    root# cat -A ServerBackup.sh | sed 's/\^M\$$//g' > backup.sh 
###############################################################################################################
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
NFSDIR="/tmp/nfs/nfsdir"
#The log file of this shell script is saving in $LOGFILE.
LOGFILE="/tmp/backup${DATE}.log"
#The NFS Server ip and export directory
NFSID="192.168.0.142:/tmp/nfsshare"
#Function Description
#camNFS implement to mount NFS and check the NFS which is mount in system.
function camNFS()
{
    /bin/mount -t nfs -o soft $NFSID $NFSDIR 1>/dev/null 2>>$LOGFILE
    LOG $? 1
    /bin/mount -l | /bin/grep $NFSID 1>/dev/null 2>&1
    LOG $? 1
}

#if you want to backup some thing that you can write down the backup command in this funciton.
function BackupData()
{
    /bin/tar -zcvf $BKPDIR$PREFIX.etc.tar.gz /etc 1>/dev/null 2>>$LOGFILE
    LOG $? 2 "/etc"
    #/usr/local/mysql/bin/mysqldump -u root -p123456 --all-databases >$BKPDIR$PREFIX.mysqld.sql 1>/dev/null 2>>$LOGFILE
    #LOG $? 2
}

#To clean you mouth if you cheat.
function CleanUp()
{
    if [ "$1" -eq 0 ]
    then
        rm -f $LOGFILE
    fi
    rm -fr ${BKPDIR}* 1>/dev/null 2>&1
}

#This function will write error log, which have three args. 
#First arg is the report about front command executed successfully or failed
#Second arg is the type of error.
#Third arg is the other information about the front command.
function LOG()
{
  if [ "$1" -ne 0 ]
  then
      case $2 in
        1)
            echo "[$(date)]: MountError: The remote directory is not mount in this system!!!" >>$LOGFILE
            exit 1;;
        2)
            echo "[$(date)]: BackupError: Couldn't backup $3 maybe permission dennis or disk is full" >>$LOGFILE
            CleanUp 1
            exit 2;;
        3)
            echo "[$(date)]: TransistError: Backup data couldn't be copyed to $NFSDIR" >>$LOGFILE
            /bin/umount $NFSDIR
            exit 3;;
        4)
            echo "[$(date)]: $3 couldn't be created" >>$LOGFILE
            echo "[$(date)]: Backup is unsuccessfully" >>$LOGFILE
            exit 4;;

        5)
            echo "[$(date)]: UMountError: Couldn't umount the NFS directory" >>$LOGFILE
            exit 5;;

      esac
  fi
}


#Follow down code is the main function.
#Initialization : 
#1. Create backup directory.
#2. Create NFS mountting directory.
#3. Create backup user whom uid is 505.
#4. Clean the old data.
echo "[$(date)]: Initialization" >>$LOGFILE
if [ ! -d $BKPDIR ]
then
        mkdir $BKPDIR 1>/dev/null 2>>$LOGFILE
        LOG $? 4 $BKPDIR
        echo "[$(date)]: backup: Create $BKPDIR directory" >>$LOGFILE
fi
if [ ! -d $NFSDIR ]
then
        mkdir -p $NFSDIR 1>/dev/null 2>>$LOGFILE
        LOG $? 4 $NFSDIR
        echo "[$(date)]: backup: Create $NFSDIR directory" >>$LOGFILE
fi
cut -d: -f3 /etc/passwd | grep '^505$' 1>/dev/null 2>&1
if [ "$?" -ne 0 ]
then
    useradd -u 505 backup && echo "[$(date)]: Adding user $(id backup)" >>$LOGFILE
    LOG $? 4 "user backup(uid=505)"
fi
CleanUp 1
echo "[$(date)]: Initialization successfully" >>$LOGFILE

#Starting BackupData function
echo "[$(date)]: Beginning backup data" >>$LOGFILE
BackupData
echo "[$(date)]: Backup successfully" >>$LOGFILE

#Starting camNFS function
echo "[$(date)]: Mount NFS directory" >>$LOGFILE
camNFS
echo "[$(date)]: Mount successfully" >>$LOGFILE

#Host creatting its own backup directory on NFS directory
if [ ! -d $NFSDIR/$HOST ]
then
    sudo -u#505 mkdir $NFSDIR/$HOST 1>/dev/null 2>>$LOGFILE
    LOG $? 4 "$NFSDIR/$HOST"
fi
echo "$NFSDIR/$HOST is existing" >>$LOGFILE

#Clean the old data from NFS directory
echo "[$(date)]: Clean the Old backup" >>$LOGFILE
sudo -u#505 rm -fr $NFSDIR/$HOST/*
echo "[$(date)]: Clean Up" >>$LOGFILE

#Starting backup transmission
echo "[$(date)]: Transisting" >>$LOGFILE
sudo -u#505 cp -a $BKPDIR* $NFSDIR/$HOST/
LOG $? 3 
echo "[$(date)]: Transist successfully" >>$LOGFILE
echo "[$(date)]: Backup data had been copyed (successfully!!!!)" >>$LOGFILE

#if you couldn't see the logfile in the NFS directory affer script done that means the backup is unsuccessfully. 
#You must cheack the log from Host.
/bin/chmod 777 $LOGFILE
sudo -u#505 cp -a $LOGFILE $NFSDIR/$HOST/
/bin/umount $NFSDIR
LOG $? 5
CleanUp 0
echo "[$(date)]: Script done!!"
exit 0
