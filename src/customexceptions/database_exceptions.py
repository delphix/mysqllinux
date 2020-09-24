#
# Copyright (c) 2020 by Delphix. All rights reserved.
#
from customexceptions.base_exceptions import DatabaseException

# Exception When MySQL Startup Fails
class StagingStartupException(DatabaseException):
    def __init__(self, message=""):
        message = "DB Startup Failure: " + message
        super(StagingStartupException, self).__init__(
            message,
            "Check error log for more details.",
            "Unable to start Staging DB"
        )

class StagingShutdownException(DatabaseException):
    def __init__(self, message=""):
        message = "DB Shutdown Failure: " + message
        super(StagingShutdownException, self).__init__(
            message,
            "Check error log for more details.",
            "Unable to Shutdown Staging DB"
        )

class MySQLShutdownException(DatabaseException):
    def __init__(self, message=""):
        message = "DB Shutdown Failure: " + message
        super(MySQLShutdownException, self).__init__(
            message,
            "Check error log for more details.",
            "Unable to Shutdown MySQL DB"
        )

class MySQLStartupException(DatabaseException):
    def __init__(self, message=""):
        message = "DB Startup Failure: " + message
        super(MySQLStartupException, self).__init__(
            message,
            "Check error log for more details.",
            "Unable to Startup MySQL DB"
        )

# Exception When MySQL Replication Setup Fails
class ReplicationSetupException(DatabaseException):
    def __init__(self, message=""):
        message = "Replication Slave Setup Failure: " + message
        super(ReplicationSetupException, self).__init__(
            message,
            "Check error log for more details.",
            "Unable to set up replication to Staging DB"
        )

# Exception When MySQL Replication StartUp Fails
class ReplicationStartupException(DatabaseException):
    def __init__(self, message=""):
        message = "Replication Startup Failure: " + message
        super(ReplicationStartupException, self).__init__(
            message,
            "Check error log for more details.",
            "Unable to start replication to Staging DB"
        )

class SourceBackupException(DatabaseException):
    def __init__(self, message=""):
        message = " There was a problem with the Backup: " + message
        super(SourceBackupException, self).__init__(
            message,
            "Check error log for more details",
            "Unable to create a Source DB backup"
        )