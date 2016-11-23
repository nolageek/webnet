#!/bin/bash
##############################################################################
# maldet-per-user
# version 0.35
# 2011-09 to 2015-09 by Nicole Hope
#
# changelog: http://scripts.ent/changelogs/maldet-per-user-changelog.txt
# how to: https://wiki.int.liquidweb.com/articles/Maldet-per-user
#
# Written to be able to start/stop/resume maldet scans for all CPanel accounts
# on a server. Most servers that warrant a scan of every user are in no shape
# to actually run such a large scan uninteruppted. This scans each user
# individually, and will skip over any previously scanned users if the scan
# is stopped.
#
# The automatic backup/quarantine functions (especially the quarantine) rely
# on maldet's output format to work correctly. This script will break if
# maldet changes its output format.
#
##############################################################################
# Path variables, modify as necessary, no trailing slashes                   #
##############################################################################
TEMPFILE="/tmp/maldet-per-user-temp"
DEFAULT_WORKDIR="/root/maldet-scan"
BACKUPDIR_BASE="/backup"
MALDET_IGNORE_PATHS="/usr/local/maldetect/ignore_paths"
##############################################################################
# date format
DATE=`date +%Y-%m-%d`

# version/compatibility/update settings
VERSION="0.35"
MALDET_COMPAT=("v1.4.0" "v1.4.1" "v1.4.2" "v1.5")
VERSION_CHECK_URL="http://scripts.ent.liquidweb.com/updates/MPU_LATEST"

##############################################################################
# Start functions                                                            #
##############################################################################

###
# fn_scan
#
# The main part of this script. Loops through /var/cpanel/users to run
# individual maldet scans on each user's public_html directory.
# 
# The loop will skip over any previously scanned users by checking for a file
# with the name of the CPanel user
#
function fn_scan {
    maldet -u > /dev/null
    if [ ! -d $WORKDIR ]; then mkdir -p $WORKDIR; fi
    userlist=$(ls /var/cpanel/users)
    usertotal=$(ls /var/cpanel/users | wc -l | awk '{print $1}')

    #workaround for maldet 1.4.2, it performs scans of /tmp, /var/tmp, and
    #/dev/shm for every invocation, so ignore these for user scans
    if [[ ! $(grep '^/tmp$' $MALDET_IGNORE_PATHS) ]]; then
        echo "/tmp" >> $MALDET_IGNORE_PATHS;
    fi
    if [[ ! $(grep '^/var/tmp$' $MALDET_IGNORE_PATHS) ]]; then
        echo "/var/tmp" >> $MALDET_IGNORE_PATHS;
    fi
    if [[ ! $(grep '^/dev/shm$' $MALDET_IGNORE_PATHS) ]]; then
        echo "/dev/shm" >> $MALDET_IGNORE_PATHS;
    fi

    for user in $userlist
    do
        count=$(echo "$userlist" | grep -n $user$ | cut -d: -f1) 
        #only scan the user's public_html directory
        #if a scan hasn't already been run
        if [ ! -e $WORKDIR/$user ]
        then
            HOMEDIR=`grep "/$user:" /etc/passwd | cut -d: -f6`
            #make sure we grabbed a valid username and homedir to scan
            #primarily this is to skip the "system" cpanel user
            if [ ! -z $HOMEDIR ]
            then
                echo "[$count/$usertotal] Scanning public_html for $user"
                maldet -co scan_ignore_root=0 -a $HOMEDIR/public_html > $TEMPFILE
                #Still a dirty way to grab maldet session id, updated to work
                #with both maldet 1.4.0 and 1.4.1
                SESSID=`grep "\--report" $TEMPFILE | awk '{print $NF}' | sed "s/'//"`
                #a maldet session file is not created if there's no files
                #to scan in the first place
                if [ -e /usr/local/maldetect/sess/session.$SESSID ]
                then
                    cp /usr/local/maldetect/sess/session.$SESSID $WORKDIR/$user
                else
                    echo "No files found" > $WORKDIR/$user
                fi
                rm $TEMPFILE
            else #homedir does not exist
                echo "Could not find a home directory for $user"
            fi
        #scan already completed for this user
        else
            echo "[$count/$usertotal] skipping scan for $user"
        fi
    done

    #Remove the tempdirs 
    sed -i '/^\/tmp$/d' $MALDET_IGNORE_PATHS
    sed -i '/^\/var\/tmp/d' $MALDET_IGNORE_PATHS
    sed -i '/^\/dev\/shm/d' $MALDET_IGNORE_PATHS

    #Scan default apache htdocs directory
    # will also force a scan of tempdirs in maldet 1.4.2
    echo "scanning /usr/local/apache/htdocs"
    maldet -co scan_ignore_root=0 -a /usr/local/apache/htdocs > $TEMPFILE
    SESSID=`grep "\--report" $TEMPFILE | awk '{print $NF}' | sed "s/'//"`
    if [ -e /usr/local/maldetect/sess/session.$SESSID ]; then
        cp /usr/local/maldetect/sess/session.$SESSID $WORKDIR/nobody
    fi
    rm $TEMPFILE
}

###
# fn_report
#
# Creates a list of all files found in the maldet scans, as well as
# the standard classification : $file format that maldet outputs
#
# The fn_backup function depends on the file list this function generates
#
function fn_report {
    REPORTFILE=/root/maldet-report.$DATE
    FILELIST=/root/maldet-files.$DATE

    # Mostly for testing, nuke an existing report file if it was generated
    # on the same day
    if [ -e $REPORTFILE ]; then rm -f $REPORTFILE; fi

    # maldet 1.4.2 now scans /tmp, /var/tmp, and /dev/shm in addition to any
    # explicitly specified paths. This will cause files in those directories
    # to show up for every user scanned. Grab the hits in those directories,
    # then filter out duplicates.
    for file in `ls $WORKDIR/`
    do
        #This isn't a perfect grep. Deal with it.
        grep "/tmp" $WORKDIR/$file >> $REPORTFILE.temp
        grep "/dev/shm" $WORKDIR/$file >> $REPORTFILE.temp
    done
    sort $REPORTFILE.temp | uniq > $REPORTFILE
    rm $REPORTFILE.temp

    # New to version 0.34+, scans /usr/local/apache/htdocs
    grep "/usr/local/apache/htdocs/" $WORKDIR/nobody >> $REPORTFILE

    # Process the actual CPanel user public_html hits 
    for file in `ls $WORKDIR/`
    do
        # grep out PATH: /home/user/public_html from the session file
        # to get just the suspect files in /home/user/public_html
        grep "/home" $WORKDIR/$file | grep -v PATH >> $REPORTFILE 
    done
    cat $REPORTFILE | cut -d: -f2 | sed 's/ //' > $FILELIST

    echo "Report saved in $REPORTFILE"
    echo "Plain file list saved in $FILELIST"
}

###
# fn_saveworkdir
#
# Just renames the current scan result directory with a date,
# so that a previous scan can be quarantined at a later date
#
function fn_saveworkdir {
    # unlikely that this will be run multiple times a day, aside from testing
    if [ -d $WORKDIR.$DATE ]
    then
        rm -rf $WORKDIR.$DATE
    fi
    mv $WORKDIR $WORKDIR.$DATE
    echo "Quarantine this finished scan with `basename $0` -q $WORKDIR.$DATE"
}

###
# fn_backup
#
# Although maldet quarantines do backup files, you'll need the session id to
# restore the maldet backup files. This copies all the suspicious files to
# a backup directory, preserving permissions and directory hierarchy for
# easy reference if a file needs to be restored/examined.
#
function fn_backup {
    BACKUPDIR=$BACKUPDIR_BASE/maldet-files.$DATE
    mkdir -p $BACKUPDIR

    echo "Copying suspicious files to $BACKUPDIR"
    for file in `cat $FILELIST`; do cp -p -f --parents $file $BACKUPDIR; done
}

###
# fn_quarantine
#
# Grabs session IDs from previous scans, then runs maldet -q to quarantine
# everything. Depends on maldet sessions not being purged.
#
function fn_quarantine {
    #dirty way to grab maldet session IDs
    grep "NOTE" $WORKDIR/* | cut -d\' -f2 | awk '{print $3}' > $TEMPFILE

    echo "Quarantining/cleaning suspicious files"
    for sessid in `cat $TEMPFILE`; do maldet -q $sessid > /dev/null; done
    rm $TEMPFILE
}

###
# fn_excludeusers
# used by --exclude argument
#
# fn_scan looks for the presence of a file matching the current CPanel username
# in the scanning loop, to determine whether or not to proceed with a scan.
# Simply touch the file to make it skip the user.
#
function fn_excludeusers {
    excluded=$1
    if [ ! -d $WORKDIR ]; then mkdir -p $WORKDIR; fi
    IFS=","
    for user in $excluded
    do
	touch $WORKDIR/$user
    done
    unset IFS
}

###
# fn_excludeusers_file
# used by --exclude-file argument
#
# fn_scan looks for the presence of a file matching the current CPanel username
# in the scanning loop, to determine whether or not to proceed with a scan.
# Simply touch the file to make it skip the user.
#
function fn_excludeusers_file {
    exclude_list=$1
    if [ ! -d $WORKDIR ]; then mkdir -p $WORKDIR; fi

    for user in `cat $exclude_list`
    do
        # Check to make sure the line was not commented out
        if [ "`echo $user | cut -c1`" != "#" ]
        then
            touch $WORKDIR/$user
        fi
    done
}

###
# fn_excludeothers
# used by --scanonly argument
#
# fn_scan looks for the presence of a file matching the current CPanel username
# in the scanning loop, to determine whether or not to proceed with a scan.
# Touch the file for all CPanel users, then remove the file for any users
# that should be explicitly scanned
# 
function fn_excludeothers {
    scanusers=$1
    if [ ! -d $WORKDIR ]; then mkdir -p $WORKDIR; fi

    userlist=$(ls /var/cpanel/users)
    for user in $userlist
    do
        touch $WORKDIR/$user
    done

    IFS=","
    for user in $scanusers
    do
        if [ -e $WORKDIR/$user ]
        then
            rm -f $WORKDIR/$user
        fi
    done
    unset IFS
}

###
# fn_excludeothers_file
# used by --scanonly-file argument
#
# fn_scan looks for the presence of a file matching the current CPanel username
# in the scanning loop, to determine whether or not to proceed with a scan.
# Touch the file for all CPanel users, then remove the file for any users
# that should be explicitly scanned
# 
function fn_excludeothers_file {
    scanlist=$1
    if [ ! -d $WORKDIR ]; then mkdir -p $WORKDIR; fi

    userlist=$(ls /var/cpanel/users)
    for user in $userlist
    do
        touch $WORKDIR/$user
    done

    for user in `cat $scanlist`
    do
        # Check to make sure the line was not commented out
        if [ "`echo $user | cut -c1`" != "#" ]
        then
            if [ -e $WORKDIR/$user ]
            then
                rm -f $WORKDIR/$user
            fi
        fi
    done
}

###
# fn_checkmaldetcompat
#
# Grab the installed maldet version, check if the version is compatible
# return 1 (true) on match, print warning and exit otherwise
#
function fn_checkmaldetcompat {
    MALDET_VERSION=`maldet -h | head -n 1 | awk '{print $NF}'`

    for compat in "${MALDET_COMPAT[@]}"
    do
        if [ $compat == $MALDET_VERSION ]
        then
            return 1
        fi
    done
    # No match? installed maldet version may not be compatible
    echo "maldet $MALDET_VERSION may not be compatible with this script"
    echo "Try scanning a single user with known malware to test compatibility:"
    echo ""
    echo "`basename $0` --skip-compat --scanonly \$username"
    echo ""
    exit 1
}

###
# fn_checkupdate
#
# curl a specified text file and compare the response to the internal version
# number 
#
function fn_checkupdate {
    which bc > /dev/null 2>&1
    local bc_exists=$?
    LATEST=`curl -fs $VERSION_CHECK_URL`
    # make sure we actually got a result
    if [[ ! -z $LATEST && $bc_exists -eq 0 ]]
    then
        if [ $(echo "$LATEST > $VERSION" | bc) -eq 1 ]
        then
            echo "`basename $0` version $VERSION - version $LATEST available"
            echo "To scan without updating, use the --skip-update flag:"
            echo ""
            echo "`basename $0` --skip-update"
            echo ""
            exit 1
        else
            echo "`basename $0` version $VERSION - no updates available"
        fi
    else
        echo "Could not check for updates, continuing"
    fi
}

###
# fn_usage
#
# prints terribly useful help message
#
function fn_usage {
    echo "Usage: `basename $0` [--reset] [-q [path]] [--exclude user1[,user2,etc]]"
    echo "       [--exclude-file file] [--scanonly user1[,user2,etc]"
    echo "       [--scanonly-file file]"
    echo ""
    echo "   no arguments: scan all users public_html directories, generate report"
    echo "      -q [path]: scan and quarantine, using previous scan results from [path]"
    echo "        --reset: remove incomplete previous scan results"
    echo "      --exclude: comma separated list of users to exclude from scans"
    echo " --exclude-file: file (one cpanel user per line, #comments allowed) of users to exclude from scans"
    echo "     --scanonly: comma separated list of users to scan, exclude other users"
    echo "--scanonly-file: file (one cpanel user per line, #comments allowed) of users to scan, exclude other users"
}

###
# fn_trapctrlc
#
# traps ctrl+c/kill signals, primarily to stop the for loop advancing in
# in the fn_scan function
# An incomplete scan will die off before copying maldet results to a file
#
function fn_trapctrlc {
    #Remove the tempdirs 
    sed -i '/^\/tmp$/d' $MALDET_IGNORE_PATHS
    sed -i '/^\/var\/tmp/d' $MALDET_IGNORE_PATHS
    sed -i '/^\/dev\/shm/d' $MALDET_IGNORE_PATHS
    echo "Exiting"
    exit 1
}

##############################################################################
# End functions                                                              #
##############################################################################

# Setup
WORKDIR=$DEFAULT_WORKDIR
QUARANTINE_MODE=0
FORCE_SCAN=0
SKIP_UPDATE=0

# Spring a ctrl+c trap
trap fn_trapctrlc SIGINT SIGTERM SIGKILL

# Parse arguments and figure out what to do
while [ $# -gt 0 ]
do
    case "$1" in
        # clear incomplete scan results
        --reset)
            rm -rf $DEFAULT_WORKDIR
            shift 1
            ;;
        # quarantine?
        -q|--quarantine)
            QUARANTINE_MODE=1
            # path to previous scan results passed?
            if [ ! -z $2 ]
            then
                WORKDIR=$2
                shift 1
            fi
            shift 1
            ;;
        # exclude users from scan
        # (list passed on the command line, comma separated)
        --exclude)
            # make sure a userlist was passed
            if [ ! -z $2 ]
            then
                fn_excludeusers $2
                shift 1
            fi
            shift 1
            ;;
        # exclude users from scan
        # (list passed as a file with one cpanel user per line)
        --exclude-file)
            # make sure a file was passed
            if [ ! -z $2 ]
            then
                fn_excludeusers_file $2
                shift 1
            fi
            shift 1
            ;;
        # scan only the listed users
        # (list passed on the command line, comma separated)
        --scanonly)
            # make sure a userlist was passed
            if [ ! -z $2 ]
            then
                fn_excludeothers $2
                shift 1
            fi
            shift 1
            ;;
        # scan only the listed users
        # (list passed as a file with one cpanel user per line)
        --scanonly-file)
            # make sure a userlist was passed
            if [ ! -z $2 ]
            then
                fn_excludeothers_file $2
                shift 1
            fi
            shift 1
            ;;
        # force a scan even if the compatibility check fails
        --skip-compat)
            FORCE_SCAN=1
            shift 1
            ;;
        # skip update check
        --skip-update)
            SKIP_UPDATE=1
            shift 1
            ;;
        # catchall, print help and exit
        *)
            fn_usage
            exit 1
    esac
done

# Check for script updates?
if [ $SKIP_UPDATE -eq 0 ]
then
    fn_checkupdate
fi

# Do a compatibility check only if a scan was not forced
if [ $FORCE_SCAN -eq 0 ]
then
    fn_checkmaldetcompat
fi

# Start working
fn_scan
fn_report
if [ $QUARANTINE_MODE -eq 1 ]
then
    fn_backup
    fn_quarantine
else
    fn_saveworkdir
fi
