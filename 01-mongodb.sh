USER_ID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop/"
LOGS_FILE="$LOGS_FOLDER/$0.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

mkdir -p $LOGS_FOLDER

if [ $USER_ID -ne 0 ]
then
    echo -e "$R Please run the script with root user $R" | tee -a $LOGS_FILE
    exit
fi

VALIDATE()
{
    if [ $1 -eq 0 ]
    then
        echo -e "$G $2 ... SUCCESS $G"  | tee -a $LOGS_FILE
    else
        echo -e "$R $2 ... FAILURE $R"  | tee -a $LOGS_FILE  
    fi
}

cp mongo.repo /etc/yum.repos.d/
VALIDATE $? "Copying of mongo repo"

dnf install mongodb-org -y
VALIDATE $? "Installing Mongodb"

systemctl enable mongod 
systemctl start mongod 
VALIDATE $? "Enabling and Starting Mongodb"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing Remote Connections"

systemctl restart mongod
VALIDATE $? "Restarting the Mongodb"
