#
# Copyright (c) 2020 by Delphix. All rights reserved.
#

#######################################################################################################################
# This module is created to define constants values which are being used in this plugin
#######################################################################################################################

# Constants
VAL = ""


ERR_START_MSG="Unable to start the MySQL database."
ERR_START_ACTION="Please make sure that" \
                         "1. Delphix user has the necessary permissions on the host " \
                         "2. Mount location provided is not in use " \
                         "3. Database credentials provided are accurate " \
                         "4. You have provided a serverid is greater than 1 "\
                         "5. Provided port is not in use."

ERR_INVALID_BINARY_MSG="An invalid path to mysql binary was passed wile provisioning."
ERR_INVALID_BINARY_ACTION="mysql was not found under the provided installation directory \n" \
                          "Please verify the MySQL directory and retry the operation."

ERR_MYCNF_MSG="MySQL configuration file (my.cnf) not found on host."
ERR_MYCNF_ACTION="Please provide a my.cnf file in the Delphix Toolkit folder on host."

ERR_PWD_MSG="An error occurred while changing password for the MySQL Staging database."
ERR_PWD_ACTION="Please check logs for further information on the error."

ERR_RESTORE_MSG="An error occurred while restoring the Staging database from Source backup."
ERR_RESTORE_ACTION="Please check logs for further information on the error."

ERR_CONNECT_MSG="Unable to connect to MySQL database."
ERR_CONNECT_ACTION="Please verify and confirm that " \
                   "1. The DB username and password are accurate " \
                   "2. The MySQL Database is running on the Host. " \
                   "Check logs for further information on the error."

ERR_INVALID_BINARY_MSG="An invalid path to mysql binary was passed wile provisioning."
ERR_INVALID_BINARY_ACTION="mysql was not found under the provided installation directory \n" \
                         "Please verify the MySQL directory and retry the operation."


ERR_GENERAL_MSG="An error occurred while provisioning the MySQL VDB."
ERR_GENERAL_ACTION="This could be due to an unsupported version of MySQL."
ERR_GENERAL_OUT="For additional details, check the log " \
               "files under the toolkit directory on Target Host."
