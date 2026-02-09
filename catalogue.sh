#!/bin/bash

USER_ID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R='\e[31m'
G='\e[32m'
Y='\e[33m'
N='\e[0m'

if [ $USER_ID -ne 0 ]; then
    echo -e "$R please run this script with root user $N" | tee -a $LOGS_FILE
    exit 1
fi
 
 
 mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 .... $R Failure $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 .... $G Success $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Diabling nodejs default version"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling nodejs 20"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Install nodejs"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
     useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
     VALIDATE $? "creating system user"
else
    echo -e "Roboshop user already exist...$Y skipping $N"
fi

mkdir -p /app 
VALIDATE $? "creating directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $? "Downloading catalogue code"

cd /app
VALIDATE $? "moving to app directory"

unzip /tmp/catalogue.zip
VALIDATE $? "unzip catalogue code"

npm install 
VALIDATE $? "installing dependencies"

cp catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "created systemctl service"

systemctl daemon-reload
systemctl enable catalogue
systemctl start catalogue
VALIDATE $? "starting and enabling catalogue"










