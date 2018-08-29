#!/bin/bash
export LANG=zh_CN.UTF-8
#about dingding
CORPID="xxxx"
SECRET="xxxx"
TIME_STAMP=`date +"%Y-%m-%d %H:%M:%S"`
ACCESS_TOKEN=`curl -s "https://oapi.dingtalk.com/gettoken?corpid=$CORPID&corpsecret=$SECRET" |  /usr/local/bin/jq .access_token | awk -F "\"" '{print $2}'`
PROCESS_CODE="xxx"
URL="https://eco.taobao.com/router/rest"
METHOD="dingtalk.smartwork.bpms.processinstance.list"
JQ="/usr/local/bin/jq"
#mysql
mysql="/usr/local/bin/mysql"
u="xxx"
p="xxx"
d="xxx"
h="1.1.1.1"
#about dir
SCRIPTPATH="/opt/script/dd_approve"
REQUESTFILE="$SCRIPTPATH/request.json"
VPNUSERLIST="$SCRIPTPATH/vpnuserlist"
DDUSERLIST="$SCRIPTPATH/dduserlist"
DDINFO="$SCRIPTPATH/ddinfo"
CONFILE="$SCRIPTPATH/openvpn_win_and_mac.rar"
USER_LOG="$SCRIPTPATH/logs/user.log"
APP_LOG="$SCRIPTPATH/logs/app.log"
DDBUSSLIST="$SCRIPTPATH/ddbusslist"
VPNBUSSLIST="$SCRIPTPATH/vpnbusslist"
#about vpn
VPN_CMD="/data/vpn/vpncmd"
ADMINHUB="my-admin-hub"
VPN_PASS="xxx"

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
function get_vpnuserlist {
$VPN_CMD /SERVER localhost /adminhub:$ADMINHUB /PASSWORD:$VPN_PASS /CMD userlist | grep "用户名" | awk -F "|" '{print $2}'
}
function newid {
#for i in $DDUSERLIST ;do grep -vwf $VPNUSERLIST $i ;done
grep -vwf  $VPNBUSSLIST $DDBUSSLIST
}
############################################################
get_vpnuserlist > $VPNUSERLIST
get_api > $REQUESTFILE
#过滤json筛选出需要的信息
cat $REQUESTFILE | grep -e value -e process_instance_result -e status  -e business_id | grep -v "form" | awk '{print $2}' | awk -F "\"" '{print $2}' > $DDINFO
#过滤json筛选出用户姓名全拼
cat $REQUESTFILE |  grep  -A 1 "姓名全拼" | grep value | awk -F ":" '{print $2}' | awk -F "\"" '{print $2}' > $DDUSERLIST
#取出审批列表
cat $REQUESTFILE |  grep "business_id" | awk -F ":" '{print $2}' | awk -F "\"" '{print $2}' > $DDBUSSLIST
newid > /dev/null
if [ $? = 0 ]
then
for i in `newid`
do
PHONE=`grep -A 4 $i $DDINFO  | sed -n '5p'`
DSTATUS=`grep -A 6 $i $DDINFO | sed -n '7p'`
COMPLETED=`grep -A 7 $i $DDINFO | sed -n '8p'`
USERNAME=`grep -A 3 $i $DDINFO | sed -n '4p'`
if [ "$DSTATUS" = agree -a "$COMPLETED" = COMPLETED ]
then
#echo "$i success"
echo "$TIME_STAMP >> $USER_LOG"
$VPN_CMD /SERVER localhost /adminhub:$ADMINHUB /PASSWORD:$VPN_PASS /CMD UserCreate  $USERNAME /Group:  /REALNAME:  /NOTE:$PHONE  >> $USER_LOG
echo "您的vpn账号已开通，用户名是姓名全拼。密码通过邮件获取，具体请查阅附件中的教程。（自动发送请勿回复）" | mail -s "账号已开通" -a $CONFILE $USERNAME@666.com
echo $i >> $VPNBUSSLIST
$mysql -h$h -u$u -p$p -D$d -e  "insert into vpn (vpn) value (\"$USERNAME\");"
else
echo "$TIME_STAMP $USERNAME 未通过审核或审核正在进行中" >> $APP_LOG
fi
done
else echo "$TIME_STAMP 无新审批用户" >> $APP_LOG
fi
