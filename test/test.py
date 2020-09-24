import re
str="mysql    25598     1  0 18:43 ?        00:00:02 /opt/mysql57/mysql-5.7.9-linux-glibc2.5-x86_64_d/bin/mysqld --defaults-file=/home/mysql/delphix/mount3/7c77eb9a-cab0-447e-9d8f-7ae5e381102b/my.cnf --basedir=/opt/mysql57/mysql57d --datadir=/home/mysql/delphix/mount3/7c77eb9a-cab0-447e-9d8f-7ae5e381102b/data --pid-file=/home/mysql/delphix/mount3/7c77eb9a-cab0-447e-9d8f-7ae5e381102b/clone.pid --port=3308 --server-id=201 --socket=/home/mysql/delphix/mount3/7c77eb9a-cab0-447e-9d8f-7ae5e381102b/mysql.sock --tmpdir=/home/mysql/delphix/mount3/7c77eb9a-cab0-447e-9d8f-7ae5e381102b/tmp"
newstr = re.sub("\s\s+", " ", str)
print(newstr)
p = newstr.split(" ")
print(p[1])
print(p[7])
print(p[10])

