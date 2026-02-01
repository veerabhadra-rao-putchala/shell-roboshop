#!/bin/bash

USER_ID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.pvraolearns.online

mkdir -p $LOGS_FOLDER

if [ $USER_ID -ne 0 ]
then
    echo -e "$R Please run the script with root user"
    exit
fi

VALIDATE()
{
     if [ $1 -eq 0 ]
     then
        echo -e "$2 $G .... SUCCESS" | tee -a $LOGS_FILE
    else
        echo -e "$2 $R .... FAILURE" | tee -a $LOGS_FILE
}

dnf module disable nodejs -y &>> $LOGS_FILE
VALIDATE $? "Disabling nodejs default version"

dnf install nodejs -y  &>> $LOGS_FILE
VALIDATE $? "Installing NodeJS"

id roboshop $>> $LOGS_FILE
if [ $? -eq 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Roboshop user created"
else
    echo -e "$N Roboshop user already exists ... $Y SKIPPING" &>> $LOGS_FILE
fi
mkdir -p /app
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> $LOGS_FILE
VALIDATE $? "Downloading catalogue code"

cd /app
VALIDATE $? "Moving to /app directory" 

rm -rf /app/* 
VALIDATE $? "Removing existing code"

unzip /tmp/catalogue.zip
VALIDATE $? "Unzipping catalogue Code"

npm install  &>>$LOGS_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload
systemctl enable catalogue  &>>$LOGS_FILE
systemctl start catalogue
VALIDATE $? "Starting and enabling catalogue"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOGS_FILE

INDEX=$(mongosh --host $MONGODB_HOST --quiet  --eval 'db.getMongo().getDBNames().indexOf("catalogue")')

if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST < /app/db/master-data.js
    VALIDATE $? "Loading products"
else
    echo -e "Products already loaded ... $Y SKIPPING $N"
fi

systemctl restart catalogue
VALIDATE $? "Restarting catalogue"


