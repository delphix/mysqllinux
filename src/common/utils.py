import logging
import random
import time
from datetime import datetime
from dlpx.virtualization import libs


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

