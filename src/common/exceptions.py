#
# Copyright (c) 2020 by Delphix. All rights reserved.
#

#######################################################################################################################
"""
Main Exception Class: UserConvertibleException
|-Two Types of exceptions: 
    |-DatabaseException - Superclass for any DB related Exception
    |-PluginException - Superclass for any plugin run-time related Exception
"""
#######################################################################################################################
from dlpx.virtualization.platform.exceptions import UserError

class UserConvertibleException(Exception):
    def __init__(self, message, action, error_string):
        super(UserConvertibleException, self).__init__(message)
        self.user_error = UserError(message, action, error_string)
    def to_user_error(self):
        return self.user_error

# DB Exceptions
class DatabaseException(UserConvertibleException):
    def __init__(self, message, action, error_string):
        super(DatabaseException, self).__init__(message, action, error_string)

# Currently for any DB action failing
class MySQLDBException(DatabaseException):
    def __init__(self, message=""):
        message = "An Error occurred during a DB Operation: " + message
        super(MySQLDBException, self).__init__(message,
                                                     "Please check the error & re-try",
                                                     "Not able perform the requested DB Operation")

# PLUGIN EXCEPTIONS

# Exceptions related to plugin operation like discovery, linking, virtualization are being handled using this.
class PluginException(UserConvertibleException):
    def __init__(self, message, action, error_string):
        super(PluginException, self).__init__(message, action, error_string)

class RepositoryDiscoveryError(PluginException):
    def __init__(self, message=""):
        message = "Not able to search repository information, " + message
        super(RepositoryDiscoveryError, self).__init__(message,
                                                       "Please check the MySQL DB installation on the environment",
                                                       "Failed to search repository information")

class MountPathError(PluginException):
    def __init__(self, message=""):
        message = "Failed to create mount path because another file system is already mounted " + message
        super(MountPathError, self).__init__(message,
                                             "Please re-try after the previous operation is completed",
                                             "Please check the logs for more details")


# This exception will be raised when failed to find source config
class SourceConfigDiscoveryError(PluginException):
    def __init__(self, message=""):
        message = "Failed to find source config, " + message
        super(SourceConfigDiscoveryError, self).__init__(message,
                                                         "An Error occured while peforming Source Discovery",
                                                         "Not able to find source")

# This exception is used for all Linking Failures
class LinkingException(PluginException):
    def __init__(self, message=""):
        message = "Failed to link source, " + message
        super(LinkingException, self).__init__(message,
                                                         "Please review the error log and re-try",
                                                         "Unable to Link dSource")

# This exception is used for all VDB Failures
class VirtualTargetException(PluginException):
    def __init__(self, message=""):
        message = "Failed while performing a VDB Operation, " + message
        super(VirtualTargetException, self).__init__(message,
                                                         "Please review the error log and re-try",
                                                         "Error while performing the VDB")


# Exception for Generic Errors
class GenericUserError(UserConvertibleException):
    def __init__(self, message="", action="", error_string=""):
        if not message:
            message = "Internal error occurred, retry again"
        if not action:
            action = "Please check logs for more details"
        if not error_string:
            error_string = "Default error string"
        super(GenericUserError, self).__init__(message, action, error_string)
