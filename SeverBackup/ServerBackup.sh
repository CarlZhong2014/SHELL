#!/bin/bash
# Program:
#   This program is create for linux server administrator to backup
#   data which include service configuration, mysql raw data, and web project etc.
# Principle:
#   The data that should be backup will be packaged by this script use tar command and will be saved under /tmp.
#   The next step is copy backup data from /tmp to nfs share directory, which is designed to backup data saving under the remote backup server.
# History：
#   2015.03.28  Frist release by CarlZhong
###############################################################################################################
/bin/mount -t nfs 192.168.0.142:/tmp/nfsshare /nfsdir
if [ "$?" -ne 0 ]
then
        echo "error mount: Couldn't mount the nfs share directory from nfs server(192.168.0.142)"
        exit 32
fi

/bin/mount -l | /bin/grep "192.168.0.142:/tmp/nfsshare"

if [ "$?" -ne 0 ]
 then
        echo "error mount: The remote directory is not mount in this system!!!"
        exit 2
fi

/bin/tar -zcvf /tmp/etcbackup.tar.gz /etc
sudo -u tom2 cp /tmp/etcbackup.tar.gz /nfsdir

if [ "$?" -ne 0 ]
then
        echo "Backup doesn't work!!"
        umount /nfsdir
        exit 3
fi
ls -l /nfsdir
echo "successfull"
rm -f /tmp/etc.tar.gz
umount /nfsdir/
exit 0
