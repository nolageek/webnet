#!/bin/sh

# place in cron job. Script assumes dumpdir = /vz/dump and tmpdir = /vz/dump/tmp
#
# usage /root/vz-backup.sh <option>
#
# Options:
# odd: backup odd numbered CIDs
# even: backup even numbered CIDSs
# one: backup first 3rd CIDs
# two: backup second 3rd CIDs
# three: backup thirt 3rd CIDs
# all: backup all CIDs


if [ $1 = "odd" ]
then
for VM in `/usr/sbin/vzlist -H -o ctid | sed 's/^[ \t]*//' | sed -n 1~2p`; do /usr/sbin/vzdump --suspend --tmpdir /vz/dump/tmp $VM; done
elif [ $1 = "even" ]
then
for VM in `/usr/sbin/vzlist -H -o ctid | sed 's/^[ \t]*//' | sed -n 2~2p`; do /usr/sbin/vzdump --suspend --tmpdir /vz/dump/tmp $VM; done
elif [ $1 = "one" ]
then
for VM in `/usr/sbin/vzlist -H -o ctid | sed 's/^[ \t]*//' | sed -n 1~3p`; do /usr/sbin/vzdump --suspend --tmpdir /vz/dump/tmp $VM; done
elif [ $1 = "two" ]
then
for VM in `/usr/sbin/vzlist -H -o ctid | sed 's/^[ \t]*//' | sed -n 2~3p`; do /usr/sbin/vzdump --suspend --tmpdir /vz/dump/tmp $VM; done
elif [ $1 = "three" ]
then
for VM in `/usr/sbin/vzlist -H -o ctid | sed 's/^[ \t]*//' | sed -n 3~3p`; do /usr/sbin/vzdump --suspend --tmpdir /vz/dump/tmp $VM; done
elif [ $1 = "all" ]
then
for VM in `/usr/sbin/vzlist -H -o ctid | sed 's/^[ \t]*//'`; do /usr/sbin/vzdump --suspend --tmpdir /vz/dump/tmp $VM; done
else
echo "no argument given."
fi
