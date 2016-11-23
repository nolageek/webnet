#!/bin/sh

C_GREEN='\033[0;32m'
C_RED='\033[0;31m'
C_YELLOW='\e[0;33m'
C_PURPLE='\e[0;35m'
C_RESET='\033[0m'

EMAIL="user@domain.com"
RSYNC='rsync -avH --progress --log-file=/root/restore.log'
ETC_files=`cat etc_files_list`
VAR_files=`cat var_files_list`

touch /root/restore.log;

echo -e $C_YELLOW 'Enter mount point for the OLD DRIVE [Default: oldHDD]:' $C_RESET
        read olddrivemnt

if [ "$olddrivemnt" == '' ]; then
        olddrivemnt='oldHDD'
        echo -e $C_GREEN "Default path used: oldHDD" $C_RESET
fi

if [ -d /$olddrivemnt/home ];then
        echo -e $C_GREEN "Found /$olddrivemnt/home" $C_RESET
else
        echo -e $C_RED "ERROR: Could not locate files/folders at /$olddrivemnt/home. Exiting." $C_RESET
        exit 1
fi

echo -e $C_PURPLE "Copy files from $olddrivemnt ? Enter y/n" $C_RESET
read confirm
        if [ "$confirm" == "n" ]; then
                echo -e $C_RED "User aborted. Type 'y' to transfer files." $C_RESET
        exit 1

        elif [ "$confirm" == "N" ]; then
                echo -e $C_RED "User aborted. Type 'y' to transfer files."  $C_RESET
        exit 1

        elif [ "$confirm" != "y" ]; then
                echo -e $C_RED "Sorry, I accept only y or n as the answer" $C_RESET
        exit 1

        else

echo -e $C_PURPLE "The rsync output is logged to /root/restore.log \n\n\n" $C_RESET

echo -e $C_YELLOW "Syncing /etc folder contents..." $C_RESET
for i in $ETC_files
do
${RSYNC} /$olddrivemnt/etc/$i /etc/
done

echo -e $C_YELLOW "Syncing /var folder contents..." $C_RESET
for i in $VAR_files
do
${RSYNC} /$olddrivemnt/var/$i /var/
done

echo -e $C_YELLOW "Syncing the 3rd-party software and specific paths" $C_RESET
${RSYNC} /$olddrivemnt/etc/sysconfig/pure-ftpd /etc/sysconfig/
${RSYNC} /$olddrivemnt/var/spool/cron /var/spool/
${RSYNC} /$olddrivemnt/usr/share/ssl /usr/share/
${RSYNC} /$olddrivemnt/usr/local/cpanel/3rdparty/mailman /usr/local/cpanel/3rdparty/
${RSYNC} /$olddrivemnt/usr/local/cpanel/base/frontend /usr/local/cpanel/base/
${RSYNC} /$olddrivemnt/usr/local/apache/conf /usr/local/apache/
${RSYNC} /$olddrivemnt/usr/local/frontpage /usr/local/
${RSYNC} /$olddrivemnt/root/.my.cnf /root/
${RSYNC} /$olddrivemnt/usr/local/lib/php.ini /usr/local/lib/
# SQL
${RSYNC} /$olddrivemnt/var/lib/mysql /var/lib/
${RSYNC} /$olddrivemnt/var/lib/pgsql /var/lib/


for SITE in `cat /$olddrivemnt/etc/userdomains | awk '{print $NF}' | sort -n | uniq`
do
${RSYNC} /$olddrivemnt/home/$SITE /home/
done

echo -e $C_YELLOW "Running cPanel services updates now" $C_RESET

/scripts/upcp --force
/scripts/eximup --force
/scripts/mysqlup --force
/scripts/easyapache
/etc/init.d/cpanel restart
/scripts/restartsrv_apache
/scripts/restartsrv_exim
/scripts/restartsrv_named

date | mail -s "Restore completed for `hostname`" $EMAIL
fi
exit 0