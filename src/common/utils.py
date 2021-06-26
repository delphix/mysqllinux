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
        err_out=std_err
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
    elif exit_code == 10: # Invalid Binary Path
        err_msg=const.ERR_INVALID_BINARY_MSG
        err_action=const.ERR_INVALID_BINARY_ACTION
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