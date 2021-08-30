#!/usr/bin/env bash

set -e

VERSION="0.0.1"

typeset -A config
typeset -A param

#
# ex: setParam "config.file.name" "config.properties"
#
function setParam() {
    echo "= set param ${1} to ${2}"
    [[ ${1} = [\#!]* ]] || [[ ${1} = "" ]] || param[$1]=${2}
    VAR=${1^^}
    export "PARAM_${VAR//./_}=${2}"
}

#
# ex: setConfig "test.name" "value"
#
# $ echo ${CONFIG_TEST_NAME}
# value
#
function setConfig() {
    if [[ "$2" =~ \[(.*)\] ]]; then
        value=${BASH_REMATCH[1]}
        storeConfigVariable "$1" "${value//,/ }"
    else
        storeConfigVariable "$1" "$2"
    fi
}

function storeConfigVariable() {
    echo "= set config ${1} to ${2}"
    [[ ${1} = [\#!]* ]] || [[ ${1} = "" ]] || config[$1]=${2}
    VAR=${1^^}
    export "CONFIG_${VAR//./_}=${2}"
}

function help() {
    echo
    echo "Usage: $0 {build <all|${config['boards']// /|}> | other} [options...]" >&2
    echo
    echo " options:"
    echo "    --working-directory=<...>         change current working directory"
    echo "    --config-path=<...>               change configuration file location path"
    echo "    --config-name=<...>               change configuration file name (current 'config.properties')"
    echo
    echo "    --organization                    prefere import repository into Github organization"
    echo
    echo " cmd:"
    echo "    import <repository_url>           import repository into Github"
    echo "    import list <[..,..,..]>"
    echo "    import file <file_path>"
    exit 0
}

# Default params config set
setParam "working.directory" "."
setParam "config.file.path" "."
setParam "config.file.name" "config.properties"

if [[ " $@ " =~ --working-directory=([^' ']+) ]]; then
    setParam "working.directory" ${BASH_REMATCH[1]}
fi

if [[ " $@ " =~ --config-path=([^' ']+) ]]; then
    setParam "config.file.path" ${BASH_REMATCH[1]}
fi

if [[ " $@ " =~ --config-name=([^' ']+) ]]; then
    setParam "config.file.name" ${BASH_REMATCH[1]}
fi

if [[ " $@ " =~ --help ]]; then
    help
fi

if [[ ! -f ${param['config.file.path']}/${param['config.file.name']} ]]; then
    echo "error: ${param['config.file.path']}/${param['config.file.name']} not found!"
    exit -1
fi

config_file=$(cat "${param['config.file.path']}/${param['config.file.name']}")

for line in ${config_file// /}; do
    if [[ "$line" =~ (.*)\=(.*) ]]; then
        setConfig ${BASH_REMATCH[1]} ${BASH_REMATCH[2]}
    fi
done

gh_extra_parameters="--confirm "

if [[ "${config['private']}" != "" ]]; then
    gh_extra_parameters+="--private "
fi

function import_repository() {
    tmp_folder=$2
    git clone --bare $1
    setParam "repository.name" ${tmp_folder}
    cd "${tmp_folder}.git"
    setParam "github.url" "git@github.com:${config['github.user']}/${tmp_folder}.git"
    if [[ " $@ " =~ --organization ]]; then
        setParam "repository.name" "${config['organization.name']}/${tmp_folder}"
        setParam "github.url" "git@github.com:${config['organization.name']}/${tmp_folder}.git"
    fi
    gh repo create ${param['repository.name']} ${gh_extra_parameters}
    git push --mirror ${param['github.url']}
    cd ..
    rm -rf "${tmp_folder}.git"
}

if [[ " $1 $2 $3 " =~ (import file ([^' ']+)) ]]; then
    for git in $(cat ${BASH_REMATCH[2]}); do
        if [[ " $git " =~ ([a-z]+)://(.*)/(.*).git ]]; then
            echo "# Import ${BASH_REMATCH[3]}"
            import_repository "$git" ${BASH_REMATCH[3]}
        fi
    done
    exit 0
fi

if [[ " $1 $2 $3 " =~ (import list (\[([^' ']+)\])) ]]; then
    gits=${BASH_REMATCH[3]}
    for git in ${gits//,/ }; do
        if [[ " $git " =~ ([a-z]+)://(.*)/(.*).git ]]; then
            echo "# Import ${BASH_REMATCH[3]}"
            import_repository "$git" ${BASH_REMATCH[3]}
        fi
    done
    exit 0
fi

if [[ " $1 $2 " =~ (import ([a-z]+)://(.*)/(.*).git) ]]; then
    echo "# Import ${BASH_REMATCH[4]}"
    import_repository "$2" ${BASH_REMATCH[4]}
    exit 0
fi

help