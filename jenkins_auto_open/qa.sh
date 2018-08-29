#!/bin/bash
USERNAME="xxx"
PASSWORD="xxx"
POSTURL="http://1.1.1.1:8080/role-strategy/strategy/assignRole"

#开通账号，传递$1和$2变量对应用户名密码
echo "hpsr=new hudson.security.HudsonPrivateSecurityRealm(false); hpsr.createAccount(\"$1\", \"$2\")" | java -jar  /var/lib/jenkins/war/WEB-INF/jenkins-cli.jar -s http://1.1.1.1:8080 groovy =

#授权，每一个roleName对应一组权限
curl -u $USERNAME:$PASSWORD -X POST $POSTURL \
-H 'Content-Type:application/x-www-form-urlencoded;charset=utf-8' \
-d 'type=globalRoles' \
-d "roleName=job_read" \
-d "sid=$1" \

curl -u $USERNAME:$PASSWORD -X POST $POSTURL \
-H 'Content-Type:application/x-www-form-urlencoded;charset=utf-8' \
-d 'type=globalRoles' \
-d "roleName=test_create" \
-d "sid=$1" \

curl -u $USERNAME:$PASSWORD -X POST  $POSTURL \
-H 'Content-Type:application/x-www-form-urlencoded;charset=utf-8' \
-d 'type=projectRoles' \
-d "roleName=qa" \
-d "sid=$1" \

curl -u $USERNAME:$PASSWORD -X POST  $POSTURL \
-H 'Content-Type:application/x-www-form-urlencoded;charset=utf-8' \
-d 'type=projectRoles' \
-d "roleName=qa_test" \
-d "sid=$1" \

curl -u $USERNAME:$PASSWORD -X POST  $POSTURL \
-H 'Content-Type:application/x-www-form-urlencoded;charset=utf-8' \
-d 'type=projectRoles' \
-d "roleName=test" \
-d "sid=$1" \

curl -u $USERNAME:$PASSWORD -X POST  $POSTURL \
-H 'Content-Type:application/x-www-form-urlencoded;charset=utf-8' \
-d 'type=projectRoles' \
-d "roleName=ucloud_qa1_trunk" \
-d "sid=$1" \

curl -u $USERNAME:$PASSWORD -X POST  $POSTURL \
-H 'Content-Type:application/x-www-form-urlencoded;charset=utf-8' \
-d 'type=projectRoles' \
-d "roleName=app" \
-d "sid=$1" \

