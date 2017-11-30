#RMAN script to delete applied archive log from svbo dr instance
#Created by: Suman Adhikari
#Created Date:29-Nov-2017

##
## Env's
##

export th1Seq=''
export th2Seq=''
export ORACLE_HOME=/u01/app/oracle/product/11.2.0.4/db_1
export ORACLE_SID=SVBO
export PATH=$PATH:$ORACLE_HOME/bin
export BACKUP_BASE=/dr_scripts/rman_scripts
export DATE_WITH_TIME=`date +%Y%m%d-%H%M%S`
export DATE_TIME=`date +%Y%m%d`
export FOLDER_NAME="DB"_$DATE_TIME


##
## Function definitions
##

getTH1seq(){
th1Seq=$($1/bin/sqlplus -s /nolog <<END
set pagesize 0 feedback off verify off echo off;
connect / as sysdba
select max(sequence#) from v\$archived_log where thread#=1 and applied='YES';
END
)
}


getTH2seq(){
th2Seq=$($1/bin/sqlplus -s /nolog <<END
set pagesize 0 feedback off verify off echo off;
connect / as sysdba
select max(sequence#) from v\$archived_log where thread#=2 and applied='YES';
END
)
}

############################# CREATING NECESSARY FOLDERS FOR BACKUP ####################################

#echo Starting Backup ................................................................................... 
#echo `date +%m%d%Y-%H%M%S` >> $BACKUP_BASE/RMAN_LOGS/DB_""$DATE_TIME.log

echo Creating backup destination folders ................................................................

echo Creating backup destination folders $BACKUP_BASE/RMAN_LOGS for RMAN Log files history...............
mkdir -p $BACKUP_BASE/RMAN_LOGS

echo Creating Log file $BACKUP_BASE/$FOLDER_NAME/LOGS/DB_""$DATE_WITH_TIME.log for current operation
export LOG_FILE_NAME=$BACKUP_BASE/RMAN_LOGS/DB_ARCH_DELETE_""$DATE_WITH_TIME.log

touch $LOG_FILE_NAME

##
## Get the last applied sequence in DR
##

getTH1seq $ORACLE_HOME
getTH2seq $ORACLE_HOME

##
## Get the last 100 sequence number
##
th1Seq=`expr $th1Seq - 100`
th2Seq=`expr $th2Seq - 100`


##
## Delete the archive logs
##

$ORACLE_HOME/bin/rman target / nocatalog log = $LOG_FILE_NAME append << EOF

run
{
        ALLOCATE CHANNEL C2 DEVICE TYPE DISK;

        DELETE NOPROMPT ARCHIVELOG UNTIL SEQUENCE $th1Seq THREAD 1;
		DELETE NOPROMPT ARCHIVELOG UNTIL SEQUENCE $th2Seq THREAD 2;
  
        RELEASE CHANNEL C2;
}

exit;


EOF

date  >> $LOG_FILE_NAME

echo 'End RMAN Script for SVBO_DR Database:'  >> $LOG_FILE_NAME

exit
