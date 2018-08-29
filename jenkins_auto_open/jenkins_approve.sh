#!/bin/bash
#about dingding
CORPID="xxxx"
SECRET="xxxx"
TIME_STAMP=`date +"%Y-%m-%d %H:%M:%S"`
ACCESS_TOKEN=`curl -s "https://oapi.dingtalk.com/gettoken?corpid=$CORPID&corpsecret=$SECRET" |  /usr/local/bin/jq .access_token | awk -F "\"" '{print $2}'`
PROCESS_CODE="xxxx"
URL="https://eco.taobao.com/router/rest"
METHOD="dingtalk.smartwork.bpms.processinstance.list"
JQ="/usr/local/bin/jq"
#mysql
mysql="/bin/mysql"
u="xxx"
p="xxx"
d="xxx"
h="1.1.1.1"
#about dir
SCRIPTPATH="/root/script/jenkins_approve"
REQUESTFILE="$SCRIPTPATH/request.json"
DDUSERLIST="$SCRIPTPATH/dduserlist"
DDINFO="$SCRIPTPATH/ddinfo"
USER_LOG="$SCRIPTPATH/logs/user.log"
APP_LOG="$SCRIPTPATH/logs/app.log"
ADDUSER="$SCRIPTPATH/adduser.py"
DDBUSSLIST="$SCRIPTPATH/ddbusslist"
JENBUSSLIST="$SCRIPTPATH/jenbusslist"
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

function newuser {
for i in $DDUSERLIST ;do grep -vwf $VPNUSERLIST $i ;done
}
get_api > $REQUESTFILE
cat $REQUESTFILE | grep -e value -e process_instance_result -e status  -e business_id | grep -v "form" | awk '{print $2}' | awk -F "\"" '{print $2}' > $DDINFO

cat $REQUESTFILE |  grep  -A 1 "姓名全拼" | grep value | awk -F ":" '{print $2}' | awk -F "\"" '{print $2}' > $DDUSERLIST

cat $REQUESTFILE |  grep "business_id" | awk -F ":" '{print $2}' | awk -F "\"" '{print $2}' > $DDBUSSLIST

function newid {
grep -vwf  $JENBUSSLIST $DDBUSSLIST
}

newid > /dev/null
if [ $? = 0 ]
then 
for i in `newid`
do
NEWUSER=`grep -A 3 $i $DDINFO | sed -n '4p'`
DSTATUS=`grep -A 5 $i $DDINFO | sed -n '6p'`
COMPLETED=`grep -A 6 $i $DDINFO | sed -n '7p'`
PASSWD=`strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 16 | tr -d '\n'; echo`
if  [ "$DSTATUS" = agree -a "$COMPLETED" = COMPLETED ]
then
/bin/sh $SCRIPTPATH/qa.sh  $NEWUSER $PASSWD
echo " $TIME_STAMP
您的Jenkins账号已开通，用户名是姓名全拼，密码是：$PASSWD
访问地址：http://1.1.1.1:8080 
" | mail -s "账号开通成功" $NEWUSER@666.com
echo "$TIME_STAMP $NEWUSER 账号成功开通。" >> $USER_LOG
echo $i >> $JENBUSSLIST
$mysql -h$h -u$u -p$p -D$d -e  "insert into jenkins (jenkins) value (\"$NEWUSER\");"
else echo "$TIME_STAMP $NEWUSER 未通过审核或审核正在进行中" >> $APP_LOG
fi
done
else echo "$TIME_STAMP 无新审批用户" >> $APP_LOG
fi




