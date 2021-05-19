#!/bin/sh
set -e

#docker run [COMMAND] not provided
if [ "$#" -eq 0 ]; then
    #/init directory exists and contain cli scripts
    if [ -d /init ] && [ $(find /init -name "*.cli" | wc -l) -gt 0 ]; then
        #start standalone server in admin only mode
        $JBOSS_HOME/bin/standalone.sh --admin-only &
        #wait for cli to be available
        jjs /wait_for_jboss_cli.js
        for s in /init/*.cli; do
            #execute cli script
            $JBOSS_HOME/bin/jboss-cli.sh --connect --file=$s
        done
        #shutdown admin only server
        $JBOSS_HOME/bin/jboss-cli.sh --connect --command=shutdown
    fi
    # start real server
    $JBOSS_HOME/bin/standalone.sh -b 0.0.0.0
else
    #docker run [COMMAND] is provided, execute it (e.g. bash)
    exec "$@"
fi
