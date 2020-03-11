SERVER_PROPERTIES_PATH=$KAFKA_HOME/config/server.properties
# $1 = key $2 = value
function override_property() {
    if [ "$#" -ne 2 ]; then
        echo -e "\e[1;32moverride_property not used correctly! Provide Key and Value parameters  \e[0m"
        exit 1
    else
        sed -i "/"$1"=/ s/=.*/="$2"/" $SERVER_PROPERTIES_PATH
    fi

}

function set_property() {
    if [ "$#" -ne 2 ]; then
        echo -e "\e[1;32mset_property not used correctly! Provide Key and Value parameters  \e[0m"
        exit 1
    else
        key_exists=$(cat $SERVER_PROPERTIES_PATH | grep -x "$1"=.*)

        if ! [ -z "$key_exists" ]; then
            override_property "$1" "$2"
        else
            echo -e "\n"$1"=""$2" >>$SERVER_PROPERTIES_PATH
        fi
    fi
}

function remove_property() {
    if [ "$#" -ne 1 ]; then
        echo -e "\e[1;32mremove_property not used correctly! Provide Key parameter  \e[0m"
        exit 1
    else
        sed -i "/^"$1"/d" $SERVER_PROPERTIES_PATH
    fi
}
