#!/bin/bash

set -e

__root_path=$(cd $(dirname $0); pwd -P)
devops_prj_path="$__root_path/devops"
source $devops_prj_path/base.sh

nginx_image=nginx:1.11
nginx_container=hk-nginx-proxy
docker_path='/data0/docker'

app=hk-nginx-proxy
app_strorage_dir="/opt/data/$app"
nginx_config_gen_dir="$app_strorage_dir/nginx-gen-config"

function _run_nginx() {

    local nginx_data_dir=$__root_path/nginx-data
    local nginx_log_path=$app_strorage_dir/logs/nginx

    local args="--restart=always -p 80:80 -p 443:443"

    # nginx config
    args="$args -v $nginx_data_dir/conf/nginx.conf:/etc/nginx/nginx.conf"

    # for the other sites
    args="$args -v $nginx_data_dir/conf/extra/:/etc/nginx/extra"

    # nginx certificate
    args="$args -v $nginx_data_dir/ssl-cert/:/etc/nginx/ssl-cert"

    # logs
    args="$args -v $nginx_log_path:/var/log/nginx"

    # generated nginx docker sites config
    args="$args -v $nginx_config_gen_dir:/etc/nginx/docker-sites"

    args="$args -v $docker_path:$docker_path"

    run_cmd "docker run -d $args --name $nginx_container $nginx_image"
}

function _send_cmd_to_ngix() {
    local cmd=$1
    run_cmd "docker exec $docker_run_fg_mode $nginx_container bash -c '$cmd'"
}

function to_nginx() {
    local cmd='bash'
    _send_cmd_to_ngix $cmd
}

function reload() {
    build_config
    cmd='nginx -s reload'
    run_cmd "docker exec $docker_run_fg_mode $nginx_container $cmd"
}

function stop() {
    stop_container $nginx_container
}

function restart() {
    stop
    run
}

function build_config() {

    local host_ip=$(docker0_ip)

    local cmd="python python/build-conf.py"
    cmd="$cmd -c $__root_path/nginx-sites-config/sites-config.yaml"
    cmd="$cmd -t $__root_path/nginx-templates"
    cmd="$cmd -o $nginx_config_gen_dir"
    cmd="$cmd --kvs host_ip=$host_ip"

    run_cmd "$cmd"
}

function run() {
    build_config
    _run_nginx
}

function _sudo_for_stroage() {
    local cmd=$1
    run_cmd "docker run --rm $docker_run_fg_mode -v /opt/data:/opt/data $nginx_image bash -c '$cmd'"
}

function clean() {
    stop
    local cmd="rm -rf $app_strorage_dir"
    _sudo_for_stroage "$cmd"
}

function help() {
        cat <<-EOF
    
    Usage: manager.sh [options]

            Valid options are:

            run
            stop
            reload
            restart
            to_nginx

            build_config
            
            -h                      show this help message and exit

EOF
}

action=${1:-help}
ALL_COMMANDS="run reload restart stop to_nginx clean build_config"
list_contains ALL_COMMANDS "$action" || action=help
$action "$@"
