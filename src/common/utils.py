import logging
import random
import time
from datetime import datetime
from dlpx.virtualization import libs
import constants as const
from dlpx.virtualization.platform.exceptions import UserError

def _setup_logger():
    # This will log the time, level, filename, line number, and log message.
    log_message_format = '[%(asctime)s] [%(levelname)s] [%(filename)s:%(lineno)d] %(message)s'
    log_message_date_format = '%Y-%m-%d %H:%M:%S'
    # Create a custom formatter. This will help with diagnosability.
    formatter = logging.Formatter(log_message_format, datefmt= log_message_date_format)
    platform_handler = libs.PlatformHandler()
    platform_handler.setFormatter(formatter)
    logger = logging.getLogger()
    logger.addHandler(platform_handler)
    # By default the root logger's level is logging.WARNING.
    logger.setLevel(logging.DEBUG)

# Create random snapshot id.
def get_snapshot_id():
    return random.randint(100000000, 999999999)

# Get Current Time
def get_current_time():
    """ Return current time in format of %Y%m%d%H%M%S'"""
    curr_time = datetime.now()
    return curr_time.strftime('%Y%m%d%H%M%S')

def process_exit_codes(exit_code,operation,std_err=None):
    """
    Processes exit code and returns a UserError
    Args:
        exit_code: Exit code from run_bash
        operation: The operation that was performed.
    Returns:
        UserError
    """
    err_out=const.ERR_GENERAL_OUT
    if std_err:
        err_out= remove_nonascii(std_err)
    if exit_code == 3:  # Unable to start MySQL
        err_msg=const.ERR_START_MSG
        err_action=const.ERR_START_ACTION
    elif exit_code == 4:  # Could not find my.cnf
        err_msg=const.ERR_MYCNF_MSG
        err_action=const.ERR_MYCNF_ACTION
    elif exit_code == 5:  # Unable to change password
        err_msg=const.ERR_PWD_MSG
        err_action=const.ERR_PWD_ACTION
    elif exit_code == 6:  # Unable restore backup
        err_msg=const.ERR_RESTORE_MSG
        err_action=const.ERR_RESTORE_ACTION
    elif exit_code == 7:  # Unable to connect after backup
        err_msg=const.ERR_CONNECT_MSG
        err_action=const.ERR_CONNECT_ACTION
    elif exit_code == 8:  # Delphix Backup failed.
        err_msg=const.ERR_BACKUP_MSG
        err_action=const.ERR_BACKUP_ACTION
    elif exit_code == 9:  # Delphix Backup failed.
        err_msg=const.ERR_CUST_BACKUP_MSG
        err_action=const.ERR_CUST_BACKUP_ACTION
    elif exit_code == 10: # Invalid Binary Path
        err_msg=const.ERR_INVALID_BINARY_MSG
        err_action=const.ERR_INVALID_BINARY_ACTION
    elif exit_code == 11: # Connection Test Failure / Backup INgestion
        err_msg=const.ERR_BI_CONNECT_MSG
        err_action=const.ERR_BI_CONNECT_ACTION
    elif exit_code == 12: # User creation issue/ Backup Ingestion
        err_msg=const.ERR_BI_USERCREATE_MSG
        err_action=const.ERR_BI_USERCREATE_ACTION
    elif exit_code == 2:
        err_msg=const.ERR_GENERAL_MSG
        err_action=const.ERR_GENERAL_ACTION

    user_error= UserError(
      err_msg,
      err_action,
      "ExitCode:{} \n {}".format(exit_code,err_out)
    )
    return user_error


def validate_repository(repo):
    """
    Sanity check to validate the repositoy string.
    Args:
        repo (string): Repository path
    Returns:
        isvalid (bool): Indicates if a repository is valid or not.
    """
    if (repo is None or repo.strip()=="" or not repo.strip().startswith("/")):
        return False
    else:
        return True

def parse_db_list(dbstr):
    """
    Parse the customer provided db list and convert to space separated string
    Args:
        dbstr (string): comma separated dblist
    Returns:
        dbs (string) : space separated  dblist
    """
    dbs=""
    if dbstr is None or dbstr.strip()=="" or dbstr.strip().upper()=="ALL":
        dbs= "ALL"
    else:
        dbstr = dbstr.strip()
        dblist = dbstr.split(",")
        for db in dblist:
            db=db.strip()
            dbs+=db
            dbs+=" "
        dbs+= "mysql"
        dbs = dbs.strip()
    return dbs

def create_backup_options(logsync, dbs, logger, aws_rds):
    """
    Creates the backup options string to be used in restore.sh script for source backup
    Args:
        logsync (string) : Are we enabling replication?
        dbs (string): Which databases are we backing up?
        aws_rds (string) : Is this an aws database.
    Returns:
         backup_options (string): Complete backup options string
    """
    backup_options="--skip-lock-tables --single-transaction --hex-blob --no-tablespaces --triggers --routines --events"
    try:
        if aws_rds!="true":
            backup_options+=" --flush-logs"
        if logsync=="true" and aws_rds!="true":
            backup_options+=" --master-data=2"
        if dbs is None or dbs=="ALL":
            backup_options+=" -A"
        else:
            backup_options+=" --databases {}".format(dbs)
        logger.debug("Returning backup_options:"+backup_options)
        return backup_options
    except Exception as err:
        user_error= UserError(
            "An exception occurred in create_backup_options() while creating DBOptions string for backup",
            "Please verify the databases list provided",
            "ExitCode:{} \n {}".format("11","Input values are / logsync:{} and dbs:{}".format(logsync,dbs))
        )

def remove_nonascii(string_nonASCII):
    """
    Removes the non ascii chars from passed string
    """
    if not string_nonASCII:
        return ""
    string_encode = string_nonASCII.encode("ascii", "ignore")
    string_decode = string_encode.decode()
    return string_decode