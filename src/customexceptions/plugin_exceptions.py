#
# Copyright (c) 2020 by Delphix. All rights reserved.
#

#######################################################################################################################
"""
Adding exceptions related to plugin.
"""
#######################################################################################################################

from customexceptions.base_exceptions import PluginException


class RepositoryDiscoveryError(PluginException):
    def __init__(self, message=""):
        message = "Finding MySQL Installations on the server, " + message
        super(RepositoryDiscoveryError, self).__init__(message,
                                                       "Check the MySQL installation. If installed at a non-standard location, please set MySQL base directory into environment variables",
                                                       "Failed to search repository information")


# This exception will be raised when failed to find source config
class SourceConfigDiscoveryError(PluginException):
    def __init__(self, message=""):
        message = "Failed to find source config, " + message
        super(SourceConfigDiscoveryError, self).__init__(message,
                                                         "Stop the MySQL service if it is running",
                                                         "Not able to find source configuration")

class MountPathError(PluginException):
    def __init__(self, message=""):
        message = "Failed to create mount path because another file system is already mounted " + message
        super(MountPathError, self).__init__(message,
                                             "Please re-try after the previous operation is completed",
                                             "Please check the logs for more details")


class UnmountFileSystemError(PluginException):
    def __init__(self, message=""):
        message = "Failed to unmount the file system from host in resync operation " + message
        super(UnmountFileSystemError, self).__init__(message,
                                                     "Please try again",
                                                     "Please check the logs for more details")

# This exception is used for all Linking Failures
class LinkingException(PluginException):
    def __init__(self, message=""):
        message = "Failed to link source, " + message
        super(LinkingException, self).__init__(message,
                                                         "Please review the error log and re-try",
                                                         "Unable to Link dSource")
# This exception is used for all VDB Failures
class VirtualException(PluginException):
    def __init__(self, message=""):
        message = "Failed to link source, " + message
        super(VirtualException, self).__init__(message,
                                                         "Please review the error log and re-try",
                                                         "Unable to Provision VDB")


ERR_RESPONSE_DATA = {
    'ERR_SOURCE_BACKUP': {
        'MESSAGE': "Error while taking Source DB Backup",
        'ACTION': "Please try again to run the previous operation",
        'ERR_STRING': "Error while generating source DB backup"
    },
    'ERR_UNABLE_TO_CONNECT': {
        'MESSAGE': "Unable to connect to host",
        'ACTION': "Please verify the defined configurations and try again",
        'ERR_STRING': "Unable to connect to host",
    },
    'ERR_BACKUP_RESTORE': {
        'MESSAGE': "Unable to restore backup",
        'ACTION': "Please try again ",
        'ERR_STRING': "There was an error while trying to restore the backup.",
    },
    'ERR_INVALID_BACKUP_DIR': {
        'MESSAGE': "Unable to restore backup",
        'ACTION': "Try again with correct archive location. ",
        'ERR_STRING': "Archive directory .* doesn't exist",
    },
    'DEFAULT_ERR': {
        'MESSAGE': "Internal error occurred, retry again",
        'ACTION': "Please check logs for more details",
        'ERR_STRING': "Default error string",
    },
}
