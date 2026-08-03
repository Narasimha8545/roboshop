#!/bin/bash
START_TIME=$(date +%s)
R="\e[31m"
G="\e[32m"
N="\e[0m"
SOURCE_DIR=$1
DEST_DIR=$2
DAYS=${3:-14} #if user does not provide days then default is 14 days

LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$( basename $0 |cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"


 

userid=$(id -u)

check_root () {
    if [ $userid -ne 0 ]
    then 
         echo -e " $R please run the script as root user $N " | tee -a $LOG_FILE
         exit 1 #give other than 0 upto 127
    else
        echo -e " $G your are running the root user $N " | tee -a $LOG_FILE
    fi

}

    validate () {
    if [ $1 -eq 0 ]
    then
        echo -e " $N $2 is .... $G successful $N" | tee -a $LOG_FILE
    else    
        echo -e " $N $2 is .... $R failed $N "| tee -a $LOG_FILE
        exit 1
    fi
    }

check_root

mkdir -p $LOGS_FOLDER

USAGE () {
    echo -e " $R USAGE::$N sh backup.sh <source_directory> <destination_directory> <days (optional)> $N"
}

if [ $# -lt 2 ]
then 
    USAGE
fi


if [ ! -d "$SOURCE_DIR" ]
then 
    echo -e " $R source directory $SOURCE_DIR does not exist $N"
    exit 1
fi

if [ ! -d "$DEST_DIR" ]
then 
    echo -e " $R destination directory $DEST_DIR does not exist $N"
    exit 1
fi

FILE=$(find $SOURCE_DIR -name "*.log" -mtime $DAYS)

if [ ! -z "$FILE" ]
then 
    echo -e " $G files older than $DAYS days are found in $SOURCE_DIR $N"
else 
    echo -e " $R no files older than $DAYS days are found in $SOURCE_DIR $N"
    exit 1
fi