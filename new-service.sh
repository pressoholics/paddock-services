#!/bin/bash

. ~/.nvm/nvm.sh
. $(brew --prefix nvm)/nvm.sh  # if installed via Brew

echo -e "\nType new service name (e.g jam3-users):"
read service_name
if [ -z $service_name ]; then
    echo "Invalid service name"
    exit
fi

git clone https://github.com/pressoholics/paddock-serverless services/$service_name-tmp

rsync -av --progress services/$service_name-tmp/ services/$service_name/ --exclude .git

rm -R -f services/$service_name-tmp

cd services/$service_name

cp .env.[env].example .env.dev

awsKeyIssue=false
echo ""
echo -e "Enter Service AWS Access Key:"
read aws_access_key

if [ -z $aws_access_key ]; then
    awsKeyIssue=true
else
    echo ""
    echo -e "Enter Service AWS Secret:"
    read aws_secret_key
    if [ -z $aws_secret_key ]; then
        awsKeyIssue=true
    fi
fi

if [ $awsKeyIssue = "false" ]; then
    sed -i '' "s,AWS_ACCESS_KEY_ID=xxxxx,AWS_ACCESS_KEY_ID=$aws_access_key,g" .env.dev
    sed -i '' "s,AWS_SECRET_ACCESS_KEY=xxxxx,AWS_SECRET_ACCESS_KEY=$aws_secret_key,g" .env.dev
    sed -i '' "s,BASE_NAME=j3-prjname,BASE_NAME=$service_name,g" .env.dev
    echo ""
    echo "Created the Service .env.dev file for you!"
    echo ""
fi

enableLocalDB=false
echo ""
echo -e "Would  you like to enable local DynamoDB (Y/N):"
read enable_local_db

if [ $enable_local_db = "Y" ]; then
    enableLocalDB=true
fi

if [ $enable_local_db = "y" ]; then
    enableLocalDB=true
fi

if [ $enableLocalDB = "false" ]; then
    sed -i '' "s,ENABLE_OFFLINE_DYNAMO=true,ENABLE_OFFLINE_DYNAMO=false,g" .env.dev
    sed -i '' "s,- serverless-dynamodb-local,#- serverless-dynamodb-local,g" serverless.yml
fi

if ! command -v nvm; then
    echo ""
    echo "#####"
    echo ""
    echo "NVM not installed, select correct node version then run npm install in new service dir"
    echo ""
    echo "#####"
    echo ""
else
    nvm use 13
    if [ ! -x "$(command -v npm)" ]; then
        echo ""
        echo "#####"
        echo ""
        echo "NPM not installed, couldn't install service packages"
        echo ""
        echo "#####"
        echo ""
    else

        echo ""
        echo "Running NPM Install..."
        echo ""
        npm install

        if [ $enable_local_db = "y" ]; then
            echo ""
            echo "Installing dynamodb local plugin..."
            echo ""
            sls dynamodb install
        fi
    fi
fi

if [ ! -x "$(command -v sg)" ]; then
    echo ""
    echo "Installing seng generator..."
    npm install -g seng-generator
    echo ""
fi

echo ""
echo "#####"
echo ""
echo "Done: here's your new service folder contents:"
echo ""
ls
echo ""
echo "Nav to path: cd services/$service_name"
if [ $awsKeyIssue = "true" ]; then
    echo ""
    echo "P.S. You will have to setup service .env.dev yourself"
fi
echo ""
echo ""
echo "### NOTE use seng generator wizard in service folder to setup Stack/Function templates ###"
echo ""
echo ""
if [ $enableLocalDB = "true" ]; then
    echo ""
    echo "Local DynamoDB plugin has been installed and enabled, see service README for more info:"
    echo ""
    echo "Run serverless command 'dynamodb start' to start local db"
    echo "Add '--migrate' param to start and import local data"
    echo ""
    echo "Setup local DB data sources in stack/db/dynamodb-local/custom-variables.yml"
fi
echo ""
echo "#####"