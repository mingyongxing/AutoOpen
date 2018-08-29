#!/bin/bash
export LANG=zh_CN.UTF-8 
#about dingding
CORPID="xxxxx"
SECRET="xxxxx"
TIME_STAMP=`date +"%Y-%m-%d %H:%M:%S"`
#获取access_token 请求时需要
ACCESS_TOKEN=`curl -s "https://oapi.dingtalk.com/gettoken?corpid=$CORPID&corpsecret=$SECRET" |  /usr/local/bin/jq .access_token | awk -F "\"" '{print $2}'`
#这是审批ID 就是要获取哪个审批的结果 就填哪个审批ID
PROCESS_CODE="xxxxxxx"
URL="https://eco.taobao.com/router/rest"
METHOD="dingtalk.smartwork.bpms.processinstance.list"
#这东西能把json格式化成容易读取的格式化
JQ="/usr/local/bin/jq"
#mysql
mysql="/usr/bin/mysql"
u="xxxxxxx"
p="xxxxxx"
d="xxxxxxxx"
h="1.1.1.1"
#about dir
SCRIPTPATH="/opt/script/dd_approve"
REQUESTFILE="$SCRIPTPATH/request.json"
SVNUSERLIST="$SCRIPTPATH/svnuserlist"
DDUSERLIST="$SCRIPTPATH/dduserlist"
DDINFO="$SCRIPTPATH/ddinfo"
USER_LOG="$SCRIPTPATH/logs/user.log"
APP_LOG="$SCRIPTPATH/logs/app.log"
SVNAUTH="/data/svn/web/conf/authz"
SVNPASSWD="/data/svn/web/conf/passwd"
ADDLOCAL="$SCRIPTPATH/addlocal.sh"
DDBUSSLIST="$SCRIPTPATH/ddbusslist"
CONFBUSSLIST="$SCRIPTPATH/confbusslist"
#Functions
function get_api {
curl -s -X  POST "$URL" \
-H 'Content-Type:application/x-www-form-urlencoded;charset=utf-8' \
-d 'format=json' \
-d "method=$METHOD" \
-d "session=$ACCESS_TOKEN" \
-d "timestamp=$TIME_STAMP" \
-d 'v=2.0' \
-d 'cursor=0' \
-d "process_code=$PROCESS_CODE" \
-d 'size=10' \
-d "start_time=1509939318000" | $JQ .
}
#这个函数是找出审批成功要开通账号的用户
function newuser {
for i in $DDUSERLIST ;do grep -vwf $VPNUSERLIST $i ;done
}
############################################################

#请求api获取审批结果，处理成json格式落地
get_api > $REQUESTFILE 

#摘出有用的数据
cat $REQUESTFILE | grep -e value -e process_instance_result -e status -e business_id | grep -v "form" | awk '{print $2}' | awk -F "\"" '{print $2}' > $DDINFO

cat $REQUESTFILE |  grep  -A 1 "姓名全拼" | grep value | awk -F ":" '{print $2}' | awk -F "\"" '{print $2}' > $DDUSERLIST

cat $REQUESTFILE |  grep "business_id" | awk -F ":" '{print $2}' | awk -F "\"" '{print $2}' > $DDBUSSLIST

#比对审批ID 如果多出来了 就说明这些审批是新审批通过的 要开通账号 
#根据这些审批ID 去落地的文件中查提交审批的用户 然后执行开通操作
function newid {
grep -vwf  $CONFBUSSLIST $DDBUSSLIST
}
newid > /dev/null
if [ $? = 0 ]
	then
		for i in `newid`
			do 
#角色是SVN里需要的，我要传递两个参数到addlocal.sh这个脚本中，这个脚本去执行开通操作
ROLE_NAME=`grep -A 4 $i $DDINFO | sed -n '5p' | awk -F "=" '{print $2}'`
DSTATUS=`grep -A 6 $i $DDINFO | sed -n '7p'`
COMPLETED=`grep -A 7 $i $DDINFO | sed -n '8p'`
NEWUSER=`grep -A 3 $i $DDINFO | sed -n '4p'`
if  [ "$DSTATUS" = agree -a "$COMPLETED" = COMPLETED ]
then
#执行开通操作
/bin/sh $ADDLOCAL $NEWUSER $ROLE_NAME 
SENDPASS=`cat /data/svn/web/conf/passwd | grep -v "^#" | grep $NEWUSER | awk -F "=" '{print $2}'`
#邮件通知
echo " $TIME_STAMP
您的svn账号已开通，用户名是姓名全拼，密码是：$SENDPASS
文档svn://2.2.2.2
代码svn://3.3.3.3
" | mail -s "账号开通成功" $NEWUSER@666.com
#插入到mysql数据库中,这个步骤和这个脚本没关系。 只是我有一个删除用户的脚本，使用到了。
$mysql -h$h -u$u -p$p -D$d -e  "insert into svn (svn) value (\"$NEWUSER\");"
echo "$TIME_STAMP $NEWUSER 账号成功开通。" >> $USER_LOG
#一定要把审批ID 打到落地文件，不然的话会一直执行开通操作。
echo $i >> $CONFBUSSLIST
else
echo "$TIME_STAMP $NEWUSER 未通过审核或审核正在进行中" >> $APP_LOG
fi
done
else echo "$TIME_STAMP 无新审批用户" >> $APP_LOG  
fi
