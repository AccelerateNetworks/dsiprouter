#!/usr/bin/env bash
#set -x
ENABLED=1 # ENABLED=1 --> install, ENABLED=0 --> do nothing, ENABLED=-1 uninstall

# Import dsip_lib utility / shared functions
. ${DSIP_PROJECT_DIR}/dsiprouter/dsip_lib.sh

function installSQL {
    # Check to see if the acc table or cdr tables are in use
    MERGE_DATA=0
    count=$(mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME -e "select count(*) from dsip_endpoint_lease limit 10" 2> /dev/null)
    if [ ${count:-0} -gt 0 ]; then
        MERGE_DATA=1
    fi

    if [ ${MERGE_DATA} -eq 1 ]; then
	    printwarn "The endpoint lease table (dsip_endpoint_lease) in Kamailio already exists. Merging table data"
	    (cat ${DSIP_PROJECT_DIR}/gui/modules/api/api.sql;
            mysqldump --single-transaction --skip-triggers --skip-add-drop-table --no-create-info --insert-ignore \
                --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" ${KAM_DB_NAME} dsip_endpoint_lease
        ) | mysql --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME
    else
        # Replace the api tables
        printwarn "Adding/Replacing the tables needed for API module within dSIPRouter..."
        mysql -s -N --user="$MYSQL_ROOT_USERNAME" --password="$MYSQL_ROOT_PASSWORD" $KAM_DB_NAME < ${DSIP_PROJECT_DIR}/gui/modules/api/api.sql
    fi
}

function install {
    installSQL
    printdbg "API module installed"
}

function uninstall {
    printdbg "API module uninstalled"
}

function main {
    if [[ ${ENABLED} -eq 1 ]]; then
        install
    elif [[ ${ENABLED} -eq -1 ]]; then
        uninstall
    else
        exit 0
    fi
}

main
