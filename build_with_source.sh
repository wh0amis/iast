#!/bin/bash

CURRENT_PATH=$(pwd)
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac

create_network(){
    docker network rm dongtai-net || true
    docker network create dongtai-net
}

build_mysql(){
    cd docker/mysql
    docker build -t huoxian/dongtai-mysql:5.7 .
    docker stop dongtai-mysql || true
    docker rm dongtai-mysql || true
    docker run -d --network dongtai-net --name dongtai-mysql --restart=always huoxian/dongtai-mysql:5.7
    cd $CURRENT_PATH
}

build_redis(){
    cd docker/redis
    docker build -t huoxian/dongtai-redis:latest .
    docker stop dongtai-redis || true
    docker rm dongtai-redis || true
    docker run -d --network dongtai-net --name dongtai-redis --restart=always huoxian/dongtai-redis:latest
    cd $CURRENT_PATH
}

build_webapi(){
    cp dongtai-webapi/conf/config.ini.example dongtai-webapi/conf/config.ini

    if [ "${machine}" == "Mac" ]; then
        sed -i "" "s/mysql-server/dongtai-mysql/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "" "s/mysql-port/3306/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "" "s/database_name/dongtai_webapi/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "" "s/mysql_username/root/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "" "s/mysql_password/dongtai-iast/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "" "s/redis_server/dongtai-redis/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "" "s/redis_port/6379/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "" "s/redis_password/123456/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "" "s/broker_db/0/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "" "s/engine_url/dongtai-engine:8000/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "" "s/api_server_url/$getip:8000/g" dongtai-webapi/conf/config.ini >/dev/null
    elif [ "${machine}" == "Linux" ]; then
        sed -i "s/mysql-server/dongtai-mysql/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "s/mysql-port/3306/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "s/database_name/dongtai_webapi/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "s/mysql_username/root/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "s/mysql_password/dongtai-iast/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "s/redis_server/dongtai-redis/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "s/redis_port/6379/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "s/redis_password/123456/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "s/broker_db/0/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "s/engine_url/dongtai-engine:8000/g" dongtai-webapi/conf/config.ini >/dev/null
        sed -i "s/api_server_url/$getip:8000/g" dongtai-webapi/conf/config.ini >/dev/null
    fi

    cd dongtai-webapi
    docker build -t huoxian/dongtai-webapi:latest .
    docker stop dongtai-webapi || true
    docker rm dongtai-webapi || true
    docker run -d --network dongtai-net --name dongtai-webapi -e debug=false --restart=always huoxian/dongtai-webapi:latest
    cd $CURRENT_PATH
}

build_openapi(){
    cp dongtai-webapi/conf/config.ini dongtai-openapi/conf/config.ini

    cd dongtai-openapi
    docker build -t huoxian/dongtai-openapi:latest .
    docker stop dongtai-openapi || true
    docker rm dongtai-openapi || true
    docker run -d --network dongtai-net -p 8000:8000 --name dongtai-openapi --restart=always huoxian/dongtai-openapi:latest
    cd $CURRENT_PATH
}

build_engine(){
    cp dongtai-webapi/conf/config.ini dongtai-engine/conf/config.ini

    cd dongtai-engine
    docker build -t huoxian/dongtai-engine:latest .
    docker stop dongtai-engine || true
    docker rm dongtai-engine || true
    docker run -d --network dongtai-net --name dongtai-engine --restart=always huoxian/dongtai-engine:latest
    cd $CURRENT_PATH
}

build_engine_task(){
    cp dongtai-webapi/conf/config.ini dongtai-engine/conf/config.ini

    cd dongtai-engine
    docker run -d --network dongtai-net --name dongtai-engine-task --restart=always huoxian/dongtai-engine:latest bash /opt/iast/engine/docker/entrypoint.sh task
    cd $CURRENT_PATH
}

build_web(){
    # ???????????????????????????
    cp dongtai-web/nginx.conf.example dongtai-web/nginx.conf
    if [ "${machine}" == "Mac" ]; then
        sed -i "" "s/lingzhi-api-svc/dongtai-webapi/g" dongtai-web/nginx.conf >/dev/null
    elif [ "${machine}" == "Linux" ]; then
        sed -i "s/lingzhi-api-svc/dongtai-webapi/g" dongtai-web/nginx.conf >/dev/null
    fi

    cd dongtai-web
    # ???????????????node??????????????????build?????????????????????????????????????????????
    # npm install
    # npm run build
    docker build -t huoxian/dongtai-web:latest .
    docker stop dongtai-web || true
    docker rm dongtai-web || true
    docker run -d -p $getip:80:80 --network dongtai-net --name dongtai-web --restart=always huoxian/dongtai-web:latest
    cd $CURRENT_PATH
}

download_source_code(){
    git submodule init
    git submodule update
}


echo "[+] ????????????????????????????????????????????????${machine}"

read -p "[+] ???????????????IP??????:" getip
echo "[*] ?????????IP??????:$getip"

echo -e "\033[33m[+] ??????????????????...\033[0m"
download_source_code
echo -e "\033[32m[*]\033[0m ?????????????????????????????????"

echo -e "\033[33m[+] ????????????????????????...\033[0m"
create_network
echo -e "\033[32m[*]\033[0m ????????????????????????"

echo -e "\033[33m[+] ????????????mysql??????...\033[0m"
build_mysql
echo -e "\033[32m[*]\033[0m mysql??????????????????"

echo -e "\033[33m[+] ????????????redis??????...\033[0m"
build_redis
echo -e "\033[32m[*]\033[0m redis??????????????????"

echo -e "\033[33m[+] ????????????dongtai-webapi??????...\033[0m"
build_webapi
echo -e "\033[32m[*]\033[0m dongtai-webapi??????????????????"

echo -e "\033[33m[+] ????????????dongtai-openapi??????...\033[0m"
build_openapi
echo -e "\033[32m[*]\033[0m dongtai-openapi??????????????????"

echo -e "\033[33m[+] ????????????dongtai-engine??????...\033[0m"
build_engine
echo -e "\033[32m[*]\033[0m dongtai-engine??????????????????"

echo -e "\033[33m[+] ????????????dongtai-engine-task??????...\033[0m"
build_engine_task
echo -e "\033[32m[*]\033[0m dongtai-engine-task??????????????????"

echo -e "\033[33m[+] ????????????dongtai-web??????...\033[0m"
build_web
echo -e "\033[32m[*]\033[0m dongtai-web??????????????????"
