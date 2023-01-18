import pkgutil
import logging
import sys
import json
from datetime import datetime
from common import utils,constants
from dlpx.virtualization import libs
from pluginops import pluginops
#from dboperations import dboperations

from dlpx.virtualization.platform import Mount, MountSpecification, Plugin, Status
from generated.definitions import (
    RepositoryDefinition,
    SourceConfigDefinition,
    SnapshotDefinition,
)
plugin = Plugin()

# Setup the logger.
utils._setup_logger()
# logging.getLogger(__name__) is the convention way to get a logger in Python.
# It returns a new logger per module and will be a child of the root logger.
# Since we setup the root logger, nothing else needs to be done to set this
# one up.
logger = logging.getLogger(__name__)

#Global Constants

#
# Below is an example of the repository discovery operation.
## NOTE: The decorators are defined on the 'plugin' object created above.
## Mark the function below as the operation that does repository discovery.
@plugin.discovery.repository()
def repository_discovery(source_connection):
    # This is an object generated from the repositoryDefinition schema.
    # In order to use it locally you must run the 'build -g' command provided
    # by the SDK tools from the plugin's root directory.
    logger.debug("Starting Repository Discovery")
    #repositories = pluginops.repository_discovery(source_connection)
    repositories = pluginops.find_mysql_binaries(source_connection)
    return repositories

# This plugin will use manual discovery for source configurations.
@plugin.discovery.source_config()
def source_config_discovery(source_connection, repository):
    #
    # To have automatic discovery of source configs, return a list of
    # SourceConfigDefinitions similar to the list of
    # RepositoryDefinitions above.
    #
    return []

# Creates an empty mount when dSource is added to Delphix.
@plugin.linked.mount_specification()
def linked_mount_specification(staged_source, repository):
    logger.debug("linked_mount_specification")
    try:
        mount_path=staged_source.parameters.mount_path
        logger.debug("Mount Path:"+mount_path)
        environment = staged_source.staged_connection.environment
        mounts = [Mount(environment, mount_path)]
    except Exception as err:
        logger.debug("ERROR: Error creating NFS Mount"+err.message)
        raise
    return MountSpecification(mounts)

@plugin.linked.start_staging()
def start_staging(staged_source, repository, source_config):
    logger.debug("linked.start_staging > Starting Staged DB")
    pluginops.start_staging(staged_source, repository, source_config)

@plugin.linked.stop_staging()
def stop_staging(staged_source, repository, source_config):
    logger.debug("linked.stop_staging > Stopping Staged DB")
    pluginops.stop_staging(staged_source, repository, source_config)

@plugin.linked.pre_snapshot()
def linked_pre_snapshot(staged_source, repository, source_config, optional_snapshot_parameters):
    logger.debug("linked_pre_snapshot > Start ")
    # Start Staging if not already running.
    pluginops.linked_pre_snapshot(staged_source, repository, source_config, optional_snapshot_parameters)
    logger.debug(" linked_pre_snapshot > End ")

@plugin.linked.post_snapshot()
def linked_post_snapshot(staged_source,repository,source_config,optional_snapshot_parameters):
    logger.debug("linked_post_snapshot - Start ")   
    snapshot = pluginops.linked_post_snapshot(staged_source,repository,source_config,optional_snapshot_parameters)
    linked_status(staged_source, repository, source_config)
    logger.debug("linked_post_snapshot - End ")                   
    return snapshot

@plugin.linked.status()
def linked_status(staged_source, repository, source_config):
    logger.debug("Checking status of Staging DB")
    return pluginops.linked_status(staged_source, repository, source_config)

@plugin.virtual.configure()
def configure(virtual_source, snapshot, repository):
    logger.debug("virtual.configure")
    srcConfig = pluginops.configure(virtual_source, snapshot, repository)
    virtual_status(virtual_source, repository, None)
    return srcConfig

@plugin.virtual.reconfigure()
def reconfigure(virtual_source, repository, source_config, snapshot):
    logger.debug("virtual.reconfigure > Start")
    start(virtual_source, repository, source_config)
    logger.debug(source_config)
    logger.debug("Snapshot")
    logger.debug(snapshot)
    #srcConfig = configure(virtual_source,snapshot,repository)
    logger.debug("virtual.reconfigure > End")
    virtual_status(virtual_source, repository, source_config)
    return SourceConfigDefinition(db_name="output",base_dir=virtual_source.parameters.base_dir, port=virtual_source.parameters.port,data_dir=virtual_source.mounts[0].mount_path)

@plugin.virtual.unconfigure()
def unconfigure(virtual_source, repository, source_config):
    logger.debug("virtual.unconfigure > Start")
    stop(virtual_source, repository, source_config)
    logger.debug("virtual.unconfigure > End")

@plugin.virtual.pre_snapshot()
def virtual_pre_snapshot(virtual_source, repository, source_config):
    logger.debug("virtual_pre_snapshot > Start")
    stop(virtual_source, repository, source_config)
    logger.debug("virtual_pre_snapshot > End")

@plugin.virtual.post_snapshot()
def virtual_post_snapshot(virtual_source, repository, source_config):
    logger.debug("virtual_post_snapshot")
    start(virtual_source, repository, source_config)
    logger.debug("Started VDB")
    snapshot = SnapshotDefinition(validate=False)
    snapshot.snapshot_id= str(utils.get_snapshot_id())
    snapshot.snap_host=virtual_source.connection.environment.host.name
    snapshot.snap_port=virtual_source.parameters.port
    snapshot.snap_data_dir=virtual_source.mounts[0].mount_path+"/data"
    snapshot.snap_base_dir=virtual_source.parameters.base_dir
    snapshot.snap_pass=virtual_source.parameters.vdb_pass
    snapshot.snap_backup_path=""
    snapshot.snap_time=utils.get_current_time()
    logger.debug("SnapShot Definition Created")
    logger.debug(snapshot)
    return snapshot

@plugin.virtual.start()
def start(virtual_source, repository, source_config):
    logger.debug("virtual.start > Start")
    pluginops.start_mysql(repository.install_path,virtual_source.parameters.base_dir,virtual_source.mounts[0].mount_path,virtual_source.parameters.port,virtual_source.parameters.server_id,virtual_source.connection)
    virtual_status(virtual_source, repository, source_config)
    logger.debug("virtual.start > End")

@plugin.virtual.stop()
def stop(virtual_source, repository, source_config):
    logger.debug("virtual.stop > Start")
    pluginops.stop_mysql(
            virtual_source.parameters.port,
            virtual_source.connection,
            virtual_source.parameters.base_dir,
            virtual_source.parameters.vdb_user,
            virtual_source.parameters.vdb_pass,
            "localhost"
    )
    logger.debug("virtual.stop > End")
    virtual_status(virtual_source, repository, source_config)

@plugin.virtual.status()
def virtual_status(virtual_source, repository, source_config):
    logger.debug("virtual.status")
    return pluginops.get_port_status(virtual_source.parameters.port,virtual_source.connection)

@plugin.virtual.mount_specification()
def virtual_mount_specification(virtual_source, repository):
    logger.debug("virtual_mount_specification")
    mount_path=virtual_source.parameters.m_path
    logger.debug("Mount Path:"+mount_path)
    environment = virtual_source.connection.environment
    mounts = [Mount(environment, mount_path)]
    return MountSpecification(mounts)

