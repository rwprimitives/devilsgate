#!/bin/bash
#
# DEVILS GATE
# ===========
#
# devilsgate is a bash script used to configure and manage a Raspberry PI
# that's been configured as a gatekeeper by forwarding any incoming traffic
# on the Raspbery PIs network interface 'ETH0' through the Tor network by
# another network interface connected to the internet.
#
# See the README.md file for more information and updates at
# https://github.com/rwprimitives/devilsgate
#


# Program information
PACKAGE="devilsgate"
FILENAME="devilsgate.sh"
VERSION="1.0.1"
AUTHOR="eldiablo"
LICENSE="BSD-3-Clause"
COPYRIGHT="Copyright (c) 2022 rwprimitives"


# Types of actions that require elevation of privileges
ACTION_CONFIG_GATEKEEPER=1
ACTION_SET_TOR_EXIT=2
ACTION_RESTART_TOR=3
ACTION_RESET_DEVICE=4


#
# The following global variables contain non-configuration values:
#
DNSMASQ_CONFIG_FILE="/etc/dnsmasq.conf"
DHCP_CONFIG_FILE="/etc/dhcpcd.conf"
SYSCTL_CONFIG_FILE="/etc/sysctl.d/local.conf"
IPTABLES_RULES_V4_FILE="/etc/iptables/rules.v4"
IPTABLES_RULES_V6_FILE="/etc/iptables/rules.v6"
KERNEL_MODULES_BLACKLIST_PATH="/etc/modprobe.d/raspi-blacklist.conf"

IPTABLES_PATH="/etc/iptables"
KERNEL_MODPROBE_PATH="/etc/modprobe.d"

TOR_SERVICE_NAME="tor.service"
TORPROJECT_URL="https://check.torproject.org/api/ip"

REQUIRED_PACKAGES="tor, iptables-persistent, curl, dnsmasq"
REQUIRED_SERVICES="tor, dnsmasq"
REQUIRED_TEST_TOOLS="torsocks, curl"


#
# The following global variables contain values that can be
# configured within the script before running devilsgate:
#
# @TODO: Add a feature to consume a configuration file
#
DNS_SERVER="1.1.1.1"

DEFAULT_KEYBOARD_LAYOUT="us"

GATEKEEPER_NIC="eth0"
GATEKEEPER_NETWORK_GATEWAY="192.168.2.1"
GATEKEEPER_NETWORK_SUBNET_MASK="255.255.255.0"
GATEKEEPER_NETWORK_SUBNET_CDIR="24"
GATEKEEPER_NETWORK_DHCP_START="192.168.2.10"
GATEKEEPER_NETWORK_DHCP_END="192.168.2.200"
GATEKEEPER_NETWORK_DHCP_TIMEOUT="24h"

TOR_CONFIG_FILE="/etc/tor/torrc"
TOR_CONFIG_IP=$GATEKEEPER_NETWORK_GATEWAY
TOR_CONFIG_DNSPORT="53"
TOR_CONFIG_TRANSPORT="9040"
TOR_CONFIG_DEFAULT_EXITNODE="us"
TOR_CONFIG_LOG="/var/log/tor/notices.log"


# POSIX Shell Colors
GREEN='\033[92m'
RED='\033[31m'
YELLOW='\033[93m'
END_COLOR='\033[0m'

#
# Source: https://www.iban.com/country-codes
# Removed (the)
#
COUNTRY_LIST="[AF] Afghanistan
[AL] Albania
[DZ] Algeria
[AS] American Samoa
[AD] Andorra
[AO] Angola
[AI] Anguilla
[AQ] Antarctica
[AG] Antigua and Barbuda
[AR] Argentina
[AM] Armenia
[AW] Aruba
[AU] Australia
[AT] Austria
[AZ] Azerbaijan
[BS] Bahamas
[BH] Bahrain
[BD] Bangladesh
[BB] Barbados
[BY] Belarus
[BE] Belgium
[BZ] Belize
[BJ] Benin
[BM] Bermuda
[BT] Bhutan
[BO] Bolivia (Plurinational State of)
[BQ] Bonaire, Sint Eustatius and Saba
[BA] Bosnia and Herzegovina
[BW] Botswana
[BV] Bouvet Island
[BR] Brazil
[IO] British Indian Ocean Territory
[BN] Brunei Darussalam
[BG] Bulgaria
[BF] Burkina Faso
[BI] Burundi
[CV] Cabo Verde
[KH] Cambodia
[CM] Cameroon
[CA] Canada
[KY] Cayman Islands
[CF] Central African Republic
[TD] Chad
[CL] Chile
[CN] China
[CX] Christmas Island
[CC] Cocos (Keeling) Islands
[CO] Colombia
[KM] Comoros
[CG] Congo
[CD] Congo, Democratic Republic of the
[CK] Cook Islands
[CR] Costa Rica
[CI] Côte d'Ivoire
[HR] Croatia
[CU] Cuba
[CW] Curaçao
[CY] Cyprus
[CZ] Czechia
[DK] Denmark
[DJ] Djibouti
[DM] Dominica
[DO] Dominican Republic
[EC] Ecuador
[EG] Egypt
[SV] El Salvador
[GQ] Equatorial Guinea
[ER] Eritrea
[EE] Estonia
[SZ] Eswatini
[ET] Ethiopia
[FK] Falkland Islands (Malvinas)
[FO] Faroe Islands
[FJ] Fiji
[FI] Finland
[FR] France
[GF] French Guiana
[PF] French Polynesia
[TF] French Southern Territories
[GA] Gabon
[GM] Gambia
[GE] Georgia
[DE] Germany
[GH] Ghana
[GI] Gibraltar
[GR] Greece
[GL] Greenland
[GD] Grenada
[GP] Guadeloupe
[GU] Guam
[GT] Guatemala
[GG] Guernsey
[GN] Guinea
[GW] Guinea-Bissau
[GY] Guyana
[HT] Haiti
[HM] Heard Island and McDonald Islands
[VA] Holy See
[HN] Honduras
[HK] Hong Kong
[HU] Hungary
[IS] Iceland
[IN] India
[ID] Indonesia
[IR] Iran (Islamic Republic of)
[IQ] Iraq
[IE] Ireland
[IM] Isle of Man
[IL] Israel
[IT] Italy
[JM] Jamaica
[JP] Japan
[JE] Jersey
[JO] Jordan
[KZ] Kazakhstan
[KE] Kenya
[KI] Kiribati
[KP] Korea (Democratic People's Republic of)
[KR] Korea, Republic of
[KW] Kuwait
[KG] Kyrgyzstan
[LA] Lao People's Democratic Republic
[LV] Latvia
[LB] Lebanon
[LS] Lesotho
[LR] Liberia
[LY] Libya
[LI] Liechtenstein
[LT] Lithuania
[LU] Luxembourg
[MO] Macao
[MG] Madagascar
[MW] Malawi
[MY] Malaysia
[MV] Maldives
[ML] Mali
[MT] Malta
[MH] Marshall Islands
[MQ] Martinique
[MR] Mauritania
[MU] Mauritius
[YT] Mayotte
[MX] Mexico
[FM] Micronesia (Federated States of)
[MD] Moldova, Republic of
[MC] Monaco
[MN] Mongolia
[ME] Montenegro
[MS] Montserrat
[MA] Morocco
[MZ] Mozambique
[MM] Myanmar
[NA] Namibia
[NR] Nauru
[NP] Nepal
[NL] Netherlands
[NC] New Caledonia
[NZ] New Zealand
[NI] Nicaragua
[NE] Niger
[NG] Nigeria
[NU] Niue
[NF] Norfolk Island
[MK] North Macedonia
[MP] Northern Mariana Islands
[NO] Norway
[OM] Oman
[PK] Pakistan
[PW] Palau
[PS] Palestine, State of
[PA] Panama
[PG] Papua New Guinea
[PY] Paraguay
[PE] Peru
[PH] Philippines
[PN] Pitcairn
[PL] Poland
[PT] Portugal
[PR] Puerto Rico
[QA] Qatar
[RE] Réunion
[RO] Romania
[RU] Russian Federation
[RW] Rwanda
[BL] Saint Barthélemy
[SH] Saint Helena, Ascension and Tristan da Cunha
[KN] Saint Kitts and Nevis
[LC] Saint Lucia
[MF] Saint Martin (French part)
[PM] Saint Pierre and Miquelon
[VC] Saint Vincent and the Grenadines
[WS] Samoa
[SM] San Marino
[ST] Sao Tome and Principe
[SA] Saudi Arabia
[SN] Senegal
[RS] Serbia
[SC] Seychelles
[SL] Sierra Leone
[SG] Singapore
[SX] Sint Maarten (Dutch part)
[SK] Slovakia
[SI] Slovenia
[SB] Solomon Islands
[SO] Somalia
[ZA] South Africa
[GS] South Georgia and the South Sandwich Islands
[SS] South Sudan
[ES] Spain
[LK] Sri Lanka
[SD] Sudan
[SR] Suriname
[SJ] Svalbard and Jan Mayen
[SE] Sweden
[CH] Switzerland
[SY] Syrian Arab Republic
[TW] Taiwan, Province of China
[TJ] Tajikistan
[TZ] Tanzania, United Republic of
[TH] Thailand
[TL] Timor-Leste
[TG] Togo
[TK] Tokelau
[TO] Tonga
[TT] Trinidad and Tobago
[TN] Tunisia
[TR] Turkey
[TM] Turkmenistan
[TC] Turks and Caicos Islands
[TV] Tuvalu
[UG] Uganda
[UA] Ukraine
[AE] United Arab Emirates
[GB] United Kingdom of Great Britain and Northern Ireland
[UM] United States Minor Outlying Islands
[US] United States of America
[UY] Uruguay
[UZ] Uzbekistan
[VU] Vanuatu
[VE] Venezuela (Bolivarian Republic of)
[VN] Viet Nam
[VG] Virgin Islands (British)
[VI] Virgin Islands (U.S.)
[WF] Wallis and Futuna
[EH] Western Sahara
[YE] Yemen
[ZM] Zambia
[ZW] Zimbabwe
[AX] Åland Islands"


LOGI()
{
    printf "${GREEN}[+]${END_COLOR} %s\n" "$1"
}

LOGW()
{
    printf "${YELLOW}[!]${END_COLOR} %s\n" "$1"
}

LOGE()
{
    printf "${RED}[-] %s ${END_COLOR}\n" "$1"
}

disable_kernel_modules()
{
    printf "%s\n%s\n%s\n%s\n"   \
           "blacklist brcmfmac" \
           "blacklist brcmutil" \
           "blacklist btbcm"    \
           "blacklist hci_uart" > $KERNEL_MODULES_BLACKLIST_PATH
}

disable_services()
{
    local services="wifi-country.service,
                    wpa_supplicant.service,
                    bluetooth.service,
                    hciuart.service,
                    avahi-daemon.service,
                    rpi-display-backlight.service,
                    triggerhappy.service,
                    triggerhappy.socket"
    local ret="0"

    for service in $(printf "%s" "$services" | sed "s/,/ /g"); do
        LOGI "Disabling $service"
        ret=$(systemctl disable "$service" &> /dev/null; echo $?)
        if [ "$ret" != "0" ]; then
            LOGW "Failed to disable $service"
        fi
    done
}

configure_tor()
{
    local country="$1"

    printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n"                   \
           "Log notice file $TOR_CONFIG_LOG"                \
           "VirtualAddrNetwork 10.192.0.0/10"               \
           "AutomapHostsOnResolve 1"                        \
           "TransPort $TOR_CONFIG_IP:$TOR_CONFIG_TRANSPORT" \
           "DNSPort $TOR_CONFIG_IP:$TOR_CONFIG_DNSPORT"     \
           "ExitNodes {$country}"                           \
           "StrictNodes 1" > $TOR_CONFIG_FILE

    touch $TOR_CONFIG_LOG
    chown debian-tor:debian-tor $TOR_CONFIG_LOG
    chmod 644 $TOR_CONFIG_LOG
}

configure_iptables()
{
    local internet_nic="$1"
    local gatekeeper_nic="$2"

    printf "%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n" \
           "*nat"                                                 \
           ":PREROUTING ACCEPT [0:0]"                             \
           ":INPUT ACCEPT [0:0]"                                  \
           ":OUTPUT ACCEPT [0:0]"                                 \
           ":POSTROUTING ACCEPT [0:0]"                            \
           "-A PREROUTING -i $gatekeeper_nic -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -j REDIRECT --to-ports $TOR_CONFIG_TRANSPORT" \
           "-A POSTROUTING -o $internet_nic -j MASQUERADE"        \
           "COMMIT"                                               \
           "*filter"                                              \
           ":INPUT ACCEPT [0:0]"                                  \
           ":FORWARD ACCEPT [0:0]"                                \
           ":OUTPUT ACCEPT [0:0]"                                 \
           "COMMIT" > $IPTABLES_RULES_V4_FILE

    printf "%s\n%s\n%s\n%s\n%s\n"   \
           "*filter"                \
           ":INPUT DROP [0:0]"      \
           ":FORWARD DROP [0:0]"    \
           ":OUTPUT DROP [0:0]"     \
           "COMMIT" > $IPTABLES_RULES_V6_FILE
}

configure_dnsmasq()
{
    local gatekeeper_nic="$1"

    printf "%s\n%s\n%s\n"               \
           "interface=$gatekeeper_nic"  \
           "    dhcp-range=$GATEKEEPER_NETWORK_DHCP_START,$GATEKEEPER_NETWORK_DHCP_END,$GATEKEEPER_NETWORK_SUBNET_MASK,$GATEKEEPER_NETWORK_DHCP_TIMEOUT" \
           "dhcp-authoritative" > $DNSMASQ_CONFIG_FILE
}

configure_dhcpd()
{
    local internet_nic="$1"
    local gatekeeper_nic="$2"

    printf "%s\n%s\n%s\n%s\n%s\n"           \
           "interface $gatekeeper_nic"      \
           "static ip_address=$GATEKEEPER_NETWORK_GATEWAY/$GATEKEEPER_NETWORK_SUBNET_CDIR"  \
           "static domain_name_servers=$GATEKEEPER_NETWORK_GATEWAY $DNS_SERVER"             \
           "denyinterfaces $gatekeeper_nic" \
           "denyinterfaces $internet_nic" > $DHCP_CONFIG_FILE
}

configure_ip_forwarding()
{
    printf "%s\n%s\n%s\n%s\n"                       \
           "net.ipv4.ip_forward=1"                  \
           "net.ipv6.conf.all.disable_ipv6=1"       \
           "net.ipv6.conf.default.disable_ipv6=1"   \
           "net.ipv6.conf.lo.disable_ipv6=1" > $SYSCTL_CONFIG_FILE
}

get_internet_nic()
{
    local default_route=""
    local nic=""
    local ret=""

    default_route=$(ip route list default)

    if [ -n "$default_route" ]; then
        ret=$(printf "%s" "$default_route" | grep -i "default via" &> /dev/null; echo $?)
        if [ "$ret" == "0" ]; then
            nic=$(ip route list default | cut -f 5 -d ' ')
        fi
    fi

    printf "%s" "$nic"
}

query_country_keywords()
{
    local keywords="$1"
    local ret=""

    LOGI "Searching for the following keyword(s): $keywords"
    while read -r line; do
        ret=$(printf "%s" "$line" | grep -i "$keywords")
        if [ "$ret" ]; then
            printf "    %s\n" "$ret"
        fi
    done <<< "$COUNTRY_LIST"
    LOGI "Search complete!"
    LOGW "Not all countries contain Tor exit relays!"
}

get_country()
{
    local country="$1"
    local ret=""

    while read -r line; do
        ret=$(printf "%s" "$line" | grep -i "\[$country\]")
        if [ -n "$ret" ]; then
            break
        fi
    done <<< "$COUNTRY_LIST"

    printf "%s" "$ret"
}

is_valid_country_code()
{
    local country="$1"
    local ret=""
    local status=0

    while read -r line; do
        ret=$(printf "%s" "$line" | grep -i "\[$country\]" &> /dev/null; echo $?)
        if [ "$ret" = "0" ]; then
            status=1
            break
        fi
    done <<< "$COUNTRY_LIST"

    printf "%s" "$status"
}

check_internet_connection()
{
    local status=0
    local ret=""

    #
    # NOTE:
    # It seems that Raspberry PI OS 64-bit doesn't contain the nc command line tool, so wget will do
    # for now. Leaving the previous line for historical purpose.
    # ret=$(echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80 > /dev/null 2>&1; echo $?)
    #
    ret=$(wget -q --delete-after http://google.com; echo $?)
    if [ "$ret" == "0" ]; then
        status=1
    fi

    printf "%s" "$status"
}

get_value_from_key()
{
    local key="$1"
    local json_data="$2"
    local clean_json=""
    local value=""
    local ret=""

    clean_json=$(printf "%s" "$json_data" | sed -e 's/["{}]//g')

    for i in $(printf "%s" "$clean_json" | tr "," "\n"); do
        ret=$(printf "%s" "$i" | grep "$key")
        if [ -n "$ret" ]; then
            value="$(printf "%s" "$ret" | sed -e "s/${key}://g" )"
        fi
    done

    printf "%s" "$value"
}

test_tor_connection()
{
    local query_ret=""
    local is_tor=""
    local ip=""
    local ret=""

    LOGI "Testing Tor connection. This could take a while..."

    for tool in $(printf "%s" "$REQUIRED_TEST_TOOLS" | sed "s/,[[:space:]]/ /g"); do
        ret=$(command -v "$tool" &> /dev/null; echo $?)
        if [ "$ret" != "0" ]; then
            LOGE "$tool is not available"
            exit 1
        fi
    done

    query_ret=$(torsocks -q curl $TORPROJECT_URL -s)
    ret=$?
    if [ "$ret" == "0" ]; then
        is_tor=$(get_value_from_key "IsTor" "$query_ret")
        ip=$(get_value_from_key "IP" "$query_ret")

        if [ "$is_tor" == "true" ]; then
            LOGI "Successful connection. Tor IP is $ip"
        else
            LOGE "Unsuccessful connection. Public facing IP is $ip"
        fi
    else
        LOGE "Failed to connect to the Tor network"
        LOGW "It's possible Tor isn't running or there aren't active Tor exit relays"
    fi
}

reset_device()
{
    local ret=""

    for service in $(printf "%s" "$REQUIRED_SERVICES" | sed "s/,[[:space:]]/ /g"); do
        LOGI "Stopping $service service"
        ret=$(systemctl stop "$service" &> /dev/null; echo $?)
        if [ "$ret" != "0" ]; then
            LOGW "Failed to stop $service service"
        fi
    done

    for package in $(printf "%s" "$REQUIRED_PACKAGES" | sed "s/,[[:space:]]/ /g"); do
        LOGI "Removing $package package"
        ret=$(apt-get purge -y "$package" &> /dev/null; echo $?)
        if [ "$ret" != "0" ]; then
            LOGW "Failed to remove $package package"
        fi
    done

    LOGI "Removing tor config file at $TOR_CONFIG_FILE"
    rm "$TOR_CONFIG_FILE" &> /dev/null

    LOGI "Removing dnsmasq config file at $DNSMASQ_CONFIG_FILE"
    rm "$DNSMASQ_CONFIG_FILE" &> /dev/null

    LOGI "Removing dhcpcd config file at $DHCP_CONFIG_FILE"
    rm "$DHCP_CONFIG_FILE" &> /dev/null

    LOGI "Removing sysctl config file at $SYSCTL_CONFIG_FILE"
    rm "$SYSCTL_CONFIG_FILE" &> /dev/null

    LOGI "Removing iptables IPv4 rules file at $IPTABLES_RULES_V4_FILE"
    rm "$IPTABLES_RULES_V4_FILE" &> /dev/null

    LOGI "Removing iptables IPv6 rules file at $IPTABLES_RULES_V6_FILE"
    rm "$IPTABLES_RULES_V6_FILE" &> /dev/null

    LOGI "Removing tor log file at $TOR_CONFIG_LOG"
    rm "$TOR_CONFIG_LOG" &> /dev/null

    LOGI "Removing kernel module blacklist file at $KERNEL_MODULES_BLACKLIST_PATH"
    rm "$KERNEL_MODULES_BLACKLIST_PATH" &> /dev/null

    LOGI "Removing packages no longer needed"
    apt-get autoremove -y &> /dev/null
    apt-get autoclean -y &> /dev/null
    apt-get clean &> /dev/null


    LOGI "Reset complete! Raspberry PI is now back to normal state"
    LOGW "Must reboot in order to apply changes!"
    printf "Press ENTER to reboot \n"
    read -r
    systemctl reboot
}

restart_tor_service()
{
    LOGI "Restarting $TOR_SERVICE_NAME"

    ret=$(systemctl restart $TOR_SERVICE_NAME &> /dev/null; echo $?)
    if [ "$ret" == "3" ]; then
        LOGW "Can't restart '$TOR_SERVICE_NAME'. Service is not running or active"
    elif [ "$ret" == "5" ]; then
        LOGE "Can't restart '$TOR_SERVICE_NAME'. Service is not installed"
    elif [ "$ret" != "0" ]; then
        LOGE "Failed to restart '$TOR_SERVICE_NAME'"
        LOGW "Run 'journalctl -e -u $TOR_SERVICE_NAME' to review logs"
    else
        LOGI "Successfully restarted $TOR_SERVICE_NAME"
    fi
}

change_tor_exit_country()
{
    local country="$1"
    local ret=""

    LOGI "Setting Tor exit relay country: $(get_country "$country")"

    ret=$(is_valid_country_code "$country")
    if [ "$ret" != "1" ]; then
        LOGE "Invalid country code: $country"
        exit 1
    fi

    if [ ! -f "$TOR_CONFIG_FILE" ]; then
        LOGE "The Tor configuration file '$TOR_CONFIG_FILE' does not exist"
        LOGW "Run $FILENAME with '-c' and desired country code to configure as gatekeeper first"
        exit 1
    fi

    # Do not check for return values when using sed
    sed -i "s/ExitNodes {.*}/ExitNodes {$country}/" $TOR_CONFIG_FILE &> /dev/null

    # Verify using grep that the change did ocurred!
    ret=$(grep "{$country}" $TOR_CONFIG_FILE &> /dev/null; echo $?)
    if [ "$ret" != 0 ]; then
        LOGE "Failed to set tor exit relay country to '$country'"
        exit 1
    fi

    LOGI "Restarting $TOR_SERVICE_NAME"
    ret=$(systemctl restart $TOR_SERVICE_NAME &> /dev/null; echo $?)
    if [ "$ret" != "0" ]; then
        LOGE "Failed to restart '$TOR_SERVICE_NAME'"
        LOGW "Run 'journalctl -e -u $TOR_SERVICE_NAME' to review logs"
        exit 1
    fi

    LOGI "Successfully updated Tor exit relay country!"
}

configure_gatekeeper()
{
    local country="$1"
    local internet_nic=""
    local ret=""

    LOGI "Configuring Raspberry PI as a gatekeeper"

    if [ -z "$country" ]; then
        LOGE "Must enter a valid two letter country code for the tor exit relay"
        exit 1
    fi

    # Find a NIC with an active network connection (this does not guarantee its connected
    # to the internet)
    internet_nic=$(get_internet_nic)
    if [ -z "$internet_nic" ]; then
        LOGE "Failed to find a network interface connected to the internet"
        exit 1
    fi
    LOGI "Detected internet connected network interface: $internet_nic"

    # Check if DNS resolution is working and can connect to the internet
    ret=$(check_internet_connection)
    if [ "$ret" != "1" ]; then
        LOGE "Failed to connect to the internet. DNS resolution may not be working"
        exit 1
    fi

    # Make sure ETH0 is UP and connected to a client
    ret=$(cat /sys/class/net/$GATEKEEPER_NIC/operstate)
    if [ "$ret" = "down" ]; then
        LOGE "gatekeeper is not connected to a client"
        exit 1
    fi
    LOGI "Detected client connected to gatekeeper network interface: $GATEKEEPER_NIC"

    LOGI "Modifying keyboard layout: $DEFAULT_KEYBOARD_LAYOUT"
    sed -i -e "s/gb/$DEFAULT_KEYBOARD_LAYOUT/g" /etc/default/keyboard

    # Perform a system update and look for errors in the apt-get output
    export DEBIAN_FRONTEND=noninteractive
    LOGI "Updating the package sources list"
    ret=$(apt-get update 2>&1 | grep -i -E "error|could not|problem"; echo $?)
    if [ "$ret" == "0" ]; then
        LOGE "An error occurred when attempting to update the package source list"
        exit 1
    fi

    # Perform a system upgrade and look for errors in the apt-get output
    LOGI "Upgrading system to the latest version. This could take a while..."
    ret=$(apt-get upgrade -y 2>&1 | grep -i -E "error|could not|problem"; echo $?)
    if [ "$ret" == "0" ]; then
        LOGE "An error occurred when attempting to upgrade system"
        exit 1
    fi

    # Install the required packages
    for package in $(printf "%s" "$REQUIRED_PACKAGES" | sed "s/,[[:space:]]/ /g"); do
        LOGI "Installing $package"
        ret=$(apt-get install -y "$package" &>/dev/null; echo $?)
        if [ "$ret" != "0" ]; then
            LOGE "Failed to install $package"
            exit 1
        fi
    done

    # Once the required packages are installed, stop any of those that are services
    for service in $(printf "%s" "$REQUIRED_SERVICES" | sed "s/,[[:space:]]/ /g"); do
        LOGI "Stopping $service service"
        ret=$(systemctl stop "$service" &> /dev/null; echo $?)
        if [ "$ret" != "0" ]; then
            LOGW "Failed to stop $service service"
        fi
    done

    LOGI "Enable IPv4 Forwarding and disable IPv6"
    configure_ip_forwarding

    LOGI "Configure dhcp service for $GATEKEEPER_NIC"
    configure_dhcpd "$internet_nic" "$GATEKEEPER_NIC"

    LOGI "Configure dnsmasq service for $GATEKEEPER_NIC"
    configure_dnsmasq "$GATEKEEPER_NIC"

    LOGI "Configure iptables"
    if [ ! -d "$IPTABLES_PATH" ]; then
        mkdir -p "$IPTABLES_PATH"
    fi
    configure_iptables "$internet_nic" "$GATEKEEPER_NIC"

    LOGI "Configure Tor service"
    LOGI "Setting Tor exit relay country: $(get_country "$country")"
    configure_tor "$country"

    # Enable and start the required services
    for service in $(printf "%s" "$services" | sed "s/,[[:space:]]/ /g"); do
        LOGI "Enabling and starting $service service"
        ret=$(systemctl enable "$service" &> /dev/null; echo $?)
        if [ "$ret" != "0" ]; then
            LOGW "Failed to enable $service service"
        fi
        ret=$(systemctl start "$service" &> /dev/null; echo $?)
        if [ "$ret" != "0" ]; then
            LOGW "Failed to start $service service"
        fi
    done

    LOGI "Disable unused services"
    disable_services

    LOGI "Disable unused kernel modules"
    if [ ! -d "$KERNEL_MODPROBE_PATH" ]; then
        mkdir -p "$KERNEL_MODPROBE_PATH"
    fi
    disable_kernel_modules

    LOGI "Setup complete! Raspberry PI is now a gatekeeper"
    LOGW "Must reboot gatekeeper in order to apply changes!"
    printf "Press ENTER to reboot \n"
    read -r
    systemctl reboot
}

print_full_version()
{
    printf "\n"
    printf "%s\n" "--------------------------------------------------------------------------------- "
    printf "%s\n" "            █ ____                    _       _                 _                 "
    printf "%s\n" " ▐█▄██▄█▌   █|  _ \    __  _ __  ___ (_) ___ | |_  ___  _ __   | |_               "
    printf "%s\n" "   ▀▀▀▀     █| | |_) / _ \| '__|/ __|| |/ __|| __|/ _ \| '_ \ | __|               "
    printf "%s\n" "   ▐██▌     █|  __/ |  __/| |   \__ \| |\__ \| |_|  __/| | | || |_                "
    printf "%s\n" "   ███▌     █|_|     \___||_|   |___/|_||___/ \__|\___||_| |_| \__|               "
    printf "%s\n" "   ████     █            ___          _                                           "
    printf "%s\n" "   ████     █           / _ \  _   _ | |_  ___  ___   _ __ ___    ___  ___        "
    printf "%s\n" " ████████   █          | | | || | | || __|/ __|/ _ \ | '_ ' _ \  / _ \/ __|       "
    printf "%s\n" "==========  █          | |_| || |_| || |_| (__| (_) || | | | | ||  __/\__ \       "
    printf "%s\n" "                        \___/  \__,_| \__|\___|\___/ |_| |_| |_| \___||___/       "
    printf "%s\n" "--------------------------------------------------------------------------------- "
    printf "%s\n" "    ____            _ __     ______      __      "
    printf "%s\n" "   / __ \___ _   __(_) /____/ ____/___ _/ /____  "
    printf "%s\n" "  / / / / _ \ | / / / / ___/ / __/ __ '/ __/ _ \ "
    printf "%s\n" " / /_/ /  __/ |/ / / (__  ) /_/ / /_/ / /_/  __/ "
    printf "%s\n" "/_____/\___/|___/_/_/____/\____/\__,_/\__/\___/  "
    printf "\n"
    printf "%s v%s\n" "$PACKAGE" "$VERSION"
    printf "%s\n" "$COPYRIGHT"
    printf "%s\n" "$LICENSE"
    printf "Written by %s" "$AUTHOR"
    printf "\n\n"
}

print_short_version()
{
    printf "%s\n" "$PACKAGE v$VERSION by $AUTHOR"
    printf "\n"
}

usage()
{
    printf "%s\n" "Usage: $FILENAME [-h] [-r] [-t] [-v] (-c | -s | -q [...])"   1>&2
    printf "\n"                                                                 1>&2
    printf "%s\n" "optional arguments:"                                         1>&2
    printf "%s\n" "  -h    show this help message and exit"                     1>&2
    printf "%s\n" "  -c    configure Raspberry PI as a gatekeeper. A two"       1>&2
    printf "%s\n" "        two letter country code can be provided optionally"  1>&2
    printf "%s\n" "        but not required [default: us]"                      1>&2
    printf "%s\n" "  -q    query for country information given a keyword"       1>&2
    printf "%s\n" "  -r    restarts tor service"                                1>&2
    printf "%s\n" "  -s    changes the tor exit relay country location"         1>&2
    printf "%s\n" "        with a given two letter country code"                1>&2
    printf "%s\n" "  -t    test tor connection"                                 1>&2
    printf "%s\n" "  -v    show program's version number and exit"              1>&2
    printf "%s\n" "  -x    reset Raspberry PI back to normal"                   1>&2
    printf "\n"                                                                 1>&2
}

main()
{
    local OPTS
    local OPTIND
    local country=""
    local keywords=""
    local ret=""
    local status=0

    #
    # REF:
    # The following link gives an example of handling an option with optional arguments:
    #   https://stackoverflow.com/a/21709328
    #
    while getopts ':c:q:s:rtvxh' OPTS
    do
        case $OPTS in
            c)
                country="${OPTARG:=$default_country}"
                if [ -z "$country" ]; then
                    country=$TOR_CONFIG_DEFAULT_EXITNODE
                fi

                print_short_version

                if [ "$(id -u)" -ne 0 ]; then
                    LOGW "Must be root to perform this action"
                    exec sudo "$0" $ACTION_CONFIG_GATEKEEPER "$country"
                    exit 0
                fi

                configure_gatekeeper "$country"
                return
                ;;
            q)
                keywords="${OPTARG}"
                if [ -z "$keywords" ]; then
                    usage
                    return
                fi

                print_short_version
                query_country_keywords "$keywords"
                return
                ;;
            r)
                print_short_version

                if [ "$(id -u)" -ne 0 ]; then
                    LOGW "Must be root to perform this action"
                    exec sudo "$0" $ACTION_RESTART_TOR
                    exit 0
                fi

                restart_tor_service
                return
                ;;
            s)
                country="${OPTARG}"
                if [ -z "$country" ]; then
                    usage
                    return
                fi

                print_short_version

                if [ "$(id -u)" -ne 0 ]; then
                    LOGW "Must be root to perform this action"
                    exec sudo "$0" $ACTION_SET_TOR_EXIT "$country"
                    exit 0
                fi

                change_tor_exit_country "$country"
                return
                ;;
            t)
                print_short_version
                test_tor_connection
                return
                ;;
            v)
                print_full_version
                return
                ;;
            x)
                print_short_version

                if [ "$(id -u)" -ne 0 ]; then
                    LOGW "Must be root to perform this action"
                    exec sudo "$0" $ACTION_RESET_DEVICE
                    exit 0
                fi

                reset_device
                return
                ;;
            h)
                usage
                return
                ;;
            :)
                if [[ "$OPTARG" = "c" ]]; then
                    print_short_version

                    if [ "$(id -u)" -ne 0 ]; then
                        LOGW "Must be root to perform this action"
                        exec sudo "$0" $ACTION_CONFIG_GATEKEEPER "$TOR_CONFIG_DEFAULT_EXITNODE"
                        exit 0
                    fi

                    configure_gatekeeper "$TOR_CONFIG_DEFAULT_EXITNODE"
                else
                    usage
                    return
                fi
                ;;
            *)
                usage
                return
                ;;
        esac
    done

    # If we got here, then no valid parameter was passed!
    usage
}


#
# FLOW OF EXECUTION
#
# Get the first parameter passed to see if there is an ACTION set.
# If an ACTION is set, then the script should be running at a higher
# privilege level. Otherwise, if no ACTION is set, then run the script
# as normal.
#

# This is the beginning of the script
ACTION=$1

if [ "$ACTION_CONFIG_GATEKEEPER" == "$ACTION" ]; then
    if [ "$(id -u)" -ne 0 ]; then
        LOGW "Failed to configure gatekeeper. Requires elevation of privileges!"
        exit 1
    fi

    configure_gatekeeper "$2"

elif [ "$ACTION_SET_TOR_EXIT" == "$ACTION" ]; then
    if [ "$(id -u)" -ne 0 ]; then
        LOGW "Failed to set Tor exit country. Requires elevation of privileges!"
        exit 1
    fi

    change_tor_exit_country "$2"

elif [ "$ACTION_RESTART_TOR" == "$ACTION" ]; then
    if [ "$(id -u)" -ne 0 ]; then
        LOGW "Failed to restart service. Requires elevation of privileges!"
        exit 1
    fi

    restart_tor_service

elif [ "$ACTION_RESET_DEVICE" == "$ACTION" ]; then
    if [ "$(id -u)" -ne 0 ]; then
        LOGW "Failed to reset Raspberry PI. Requires elevation of privileges!"
        exit 1
    fi

    reset_device
else
    main "$@"
fi
