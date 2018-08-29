#!/bin/bash
SVNAUTH="/data/svn/web/conf/authz"
SVNPASSWD="/data/svn/web/conf/passwd"
DOCAUTH="/data/svn/doc/conf/authz"
DOCPASSWD="/data/svn/doc/conf/passwd"
user_name=$1
role_name=$2
KEY="/home/svn/svn"
IP="1.1.1.1"
# 生成一个密码
pd=`strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 16 | tr -d '\n'; echo`

#本地svn新增用户名密码
echo "$user_name=$pd" >> $SVNPASSWD
sed -i "1,25{/${role_name}/ s/$/,${user_name}/}"  $SVNAUTH
#取出本地svn的密码方便给另一个svn添加相同的密码
SENDPASS=`cat /data/svn/web/conf/passwd | grep -v "^#" | grep -w $1 | awk -F "=" '{print $2}'`

#ssh过去添加密码
ssh -i $KEY root@$IP > /dev/null 2>&1 << eeooff
echo "$user_name=$SENDPASS" >> $DOCPASSWD
sed -i "1,25{/${role_name}/ s/$/,${user_name}/}"  $DOCAUTH
eeooff


