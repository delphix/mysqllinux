#
# Copyright (c) 2020 by Delphix. All rights reserved.
#

#######################################################################################################################
"""
We are defining two base classes for two types of exceptions: one is related to database & the other one is for
run-time errors in the plugin. Both classes are child class of Exception which is defined inside python
The purpose of segregation of these two kinds of exceptions is to get a more accurate message at runtime error.
All the exceptions created for the database will inherit the DatabaseException and these are defined in the current package
"""
#######################################################################################################################
from dlpx.virtualization.platform.exceptions import UserError


class UserConvertibleException(Exception):
    def __init__(self, message, action, error_string):
        super(UserConvertibleException, self).__init__(message)
        # Create the UserError now in case someone asks for it later
        self.user_error = UserError(message, action, error_string)

    def to_user_error(self):
        return self.user_error


class DatabaseException(UserConvertibleException):
    def __init__(self, message, action, error_string):
        super(DatabaseException, self).__init__(message, action, error_string)


# Exceptions related to plugin operation like discovery, linking, virtualization are being handled using this.
# plugin_exceptions.py is responsible to catch and throw specific error message for each kind of delphix operation.
class PluginException(UserConvertibleException):
    def __init__(self, message, action, error_string):
        super(PluginException, self).__init__(message, action, error_string)


class GenericUserError(UserConvertibleException):
    def __init__(self, message="", action="", error_string=""):
        if not message:
            message = "Internal error occurred, retry again"
        if not action:
            action = "Please check logs for more details"
        if not error_string:
            error_string = "Default error string"
        super(GenericUserError, self).__init__(message, action, error_string)
