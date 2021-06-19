#
# Copyright (c) 2020 by Delphix. All rights reserved.
#

#######################################################################################################################
"""
CommandFactory class contains all commands required to perform MySQL and OS related operations
These are a list of commands which are being used in this project. Have segregated both types of commands into two
classes 
    DatabaseCommand
    OSCommand. 

CommandFactory is the actual class through which the command string will be returned. 
Through which we can see the actual command is going to execute. 
All methods are decorated to @staticmethod,
so no need to create an object of the class, we can use the direct class name to use any command method
"""
#######################################################################################################################


class OSCommand(object):
    def __init__(self):
        pass

    @staticmethod
    def find_binary_path():
        return "find / ! -path \"/etc/*\" ! -path \"/var/lock/*\" -name mysqld -type f -print 2>&1 | grep -v 'Permission denied'"

    @staticmethod
    def find_install_path(binary_path):
        return "find {binary_path} -name mysqld".format(binary_path=binary_path)

    @staticmethod
    def get_process():
        return "ps -ef"

    @staticmethod
    def make_directory(directory_path):
        return "mkdir -p {directory_path}".format(directory_path=directory_path)

    @staticmethod
    def change_permission(directory_path):
        return "chmod -R 775 {directory_path}".format(directory_path=directory_path)

    @staticmethod
    def get_config_directory(mount_path):
        return "{mount_path}/.delphix".format(mount_path=mount_path)

    @staticmethod
    def read_file(filename):
        return "cat {filename}".format(filename=filename)

    @staticmethod
    def check_file(file_path):
        return "[ -f {file_path} ] && echo 'Found'".format(file_path=file_path)

    @staticmethod
    def write_file(filename, data):
        return "echo {data} > {filename}".format(filename=filename, data=data)

    @staticmethod
    def get_ip_of_hostname():
        return "hostname -i"

    @staticmethod
    def check_directory(dir_path):
        return "[ -d {dir_path} ] && echo 'Found'".format(dir_path=dir_path)

    @staticmethod
    def delete_file(filename):
        return "rm  -f  {filename}".format(filename=filename)

    @staticmethod
    def get_dlpx_bin():
        return "echo $DLPX_BIN_JQ"

    @staticmethod
    def unmount_file_system(mount_path):
        return "sudo /bin/umount {mount_path}".format(mount_path=mount_path)



class DatabaseCommand(object):
    def __init__(self):
        pass

    @staticmethod
    def get_port_status(port,version):
        if(version =='1'):
            return "ps -ef | grep -E \"[m]ysqld .*--port="+port+"\" | grep -v grep"
        else:
            return "ps -ef | grep -E \"[m]ysqld .*-p.*"+port+" | grep -v grep"

    @staticmethod
    def start_mysql(installPath,baseDir,mountPath,port,serverId):
        startup_cmd= "%s/mysqld --defaults-file=%s/my.cnf --basedir=%s --datadir=%s/data \
            --pid-file=%s/clone.pid --port=%s --server-id=%s --socket=%s/mysql.sock \
                --tmpdir=%s/tmp </dev/null >/dev/null 2>&1 & disown \"$!\"" % (installPath,mountPath,baseDir,mountPath,mountPath,port,serverId,mountPath,mountPath)
        return startup_cmd

    @staticmethod
    def stop_mysql(baseDir,vdbConn,pwd,port):
        stop_cmd= "%s/bin/mysqladmin %s'%s' --protocol=TCP --port=%s shutdown" % (baseDir,vdbConn,pwd,port)
        return stop_cmd

    @staticmethod
    def get_process_id(port):
        process_cmd="ps -ef | grep -E \"[m]ysqld .*--port=%s\"" % (port)
        return process_cmd

    @staticmethod
    def kill_process(processId):
        kill_cmd= "kill -9 %s" % (processId)
        return kill_cmd

    # Used only by the hybrid code to build connection string for .sh files
    @staticmethod
    def build_lua_connect_string(user,host):
        connStr="-u%s --host=%s -p" % (user,host)
        return connStr


    @staticmethod
    def connect_to_mysql(installPath,port,connString,username,pwd,hostIp):
        connection_cmd=""
        if connString=="":
            connection_cmd="%s/mysql-u%s -p'%s' \
                --host=%s --port=%s --protocol=TCP " % (installPath,username,pwd,hostIp,port)
        else:
            connection_cmd="%s/mysqladmin %s'%s' \
                --port=%s --protocol=TCP" % (installPath,connString,pwd,port)
        return connection_cmd

    @staticmethod
    def get_version(install_path):
        return "{install_path} --version".format(install_path=install_path)

    @staticmethod
    def start_replication(connection,installPath,port,connString,username,pwd,hostIp):
        if connString=="":
            start_slave_cmd="%s/mysqladmin -u%s -p'%s' \
                --host=%s --port=%s --protocol=TCP \
                    start-slave" % (installPath,username,pwd,hostIp,port)     
        else:
            start_slave_cmd="%s/mysqladmin %s'%s' \
                --port=%s --protocol=TCP \
                    start-slave" % (installPath,connString,pwd,port) 
        return start_slave_cmd

    @staticmethod
    def stop_replication(connection,installPath,port,connString,username,pwd,hostIp):
        if connString=="":
            stop_slave_cmd="%s/mysqladmin -u%s -p'%s' \
                --host=%s --port=%s --protocol=TCP \
                    stop-slave" % (installPath,username,pwd,hostIp,port)     
        else:
            stop_slave_cmd="%s/mysqladmin %s'%s' \
                --port=%s --protocol=TCP \
                    stop-slave" % (installPath,connString,pwd,port) 
        return stop_slave_cmd

class CommandFactory(DatabaseCommand, OSCommand):
    def __init__(self):
        DatabaseCommand.__init__(self)
        OSCommand.__init__(self)

# Print Test Values
if __name__ == "__main__":
    print("\n****Test Above Commands With Dummy Values****\n")
    install_path = "DummyInstallPath"
    binary_path = "/opt/mysql/bin"
    hostname = "hostname"
    port = "3320"
    print "find_install_path: ", CommandFactory.find_install_path(binary_path), "\n"
