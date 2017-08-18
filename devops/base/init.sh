#!/bin/bash

# define: load_init_module
# defined: init_config_by_developer_name($developer_name) / load_config($developer_name) / do_init($developer_name)
manager_config_file="$devops_prj_path/auto-gen.developer-name.config"

function _try_load_config() {
    if [ ! -f "$manager_config_file" ]; then
        echo 'Config file is not found, please call `sh manager.sh init developer_name` first.'
        exit 1
    fi
    source $manager_config_file
    load_config $developer_name
}

function init() {
    echo "developer_name: $developer_name"
    echo "developer_name=$developer_name" > $manager_config_file
    do_init $developer_name
}


if [ "$load_init_module" == "1" ]; then
    if [ "$action" = 'init' ]; then
        if [ $# -lt 2 ]; then
            echo "Usage sh $0 init developer_name";
            exit 1
        fi
        developer_name=$2
        init_config_by_developer_name $developer_name
        init $developer_name
        exit 0
    else
        _try_load_config
        init_config_by_developer_name $developer_name
    fi
fi
