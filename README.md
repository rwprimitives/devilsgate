# DEVILS GATE

**devilsgate** is a bash script used to configure and manage a Raspberry PI that's been configured as a **gatekeeper** by forwarding any incoming traffic on the Raspberry PIs network interface `ETH0` through the Tor network by another network interface connected to the internet.


## CONCEPT

The idea of configuring a Raspberry PI as a **gatekeeper** is to forward all network data coming from one or multiple clients connected to `ETH0` on the Raspberry PI through the Tor network. This prevents any accidental leakage and guarantees that any client connected to the Raspberry PI via the `ETH0` network interface goes through the Tor network.

## SETUP

The following diagram describes the ideal setup with a **gatekeeper**:

    __________                     __________
    |        |                     |        |           connection to internet     __________
    |        |                     |        |[      ]-----------------------------(          )
    | user   |[      ]     [      ]| gate   |[ usb0 ]   tor network pipe          ( internet )
    | system |[ eth0 ]=====[ eth0 ]| keeper |[  or  ]=============================( provider )
    |        |[      ]     [      ]|        |[ eth1 ]-----------------------------(__________)
    |        |                     |        |
    ----------                     ----------

The secondary network interface controller in the gatekeeper could be either a USB-to-ETHERNET adapter or USB tethering using a cellphone which would be connected to the internet.


## FEATURES

**devilsgate** provides several command line options and arguments to help manage a **gatekeeper**.


### CONFIGURE GATEKEEPER

A Raspberry PI can be configured as a **gatekeeper** by using the `-c` option. By default, the Tor exit country is set to `US`. However, you can specify a country code after the `-c` option. See the example below:

    # Configure a gatekeeper to exit out of Canada
    ./devilsgate.sh -c ca


### QUERY COUNTRY INFO

Remembering two letter country codes is hard. So **devilsgate** makes it easier on you by providing a way to query for any country given a keyword. It will print out any country that contains that keyword and hopefully the result will contain the desired output.

For example, I need the two letter country code for Bulgaria and I don't know how to spell Bulgaria but I know it starts with `bul`. You can use **devilsgate** and search for `bul` as such:

    ./devilsgate.sh -q bul
    [+] Searching for the following keyword(s): bul
        [BG] Bulgaria
    [+] Search complete!
    [!] Not all countries contain Tor exit relays!

As you can see the result above, **devilsgate** found a match that contained the keyword 'bul'. However, notice the warning message indicating that not all countries contain Tor exit relays. To find out if a country contains Tor exit relays, use torseeker to perform a query on the desired country.


### SET TOR EXIT COUNTRY

**devilsgate** can be used to change the Tor exit country with the '-s' flag followed by the desired country code, as such:

    # Change the Tor exit country to Brazil
    ./devilsgate.sh -s br


### RESTART TOR SERVICE

**devilsgate** allows you to restart the Tor service if necessary.

    ./devilsgate.sh -r


### TEST CONNECTION

**devilsgate** provides a way to test if you have an active connection to the Tor network. It is highly suggested that after changing the Tor exit country to verify that there is still an active connection. Not all countries contain active Tor exit relays, so it is possible that you may lose connection to the Tor network.

    ./devilsgate.sh -t


## CONTRIBUTIONS

Contributions to the project can be made by doing one of the following:

1. Check for open issues before submitting a feature or bug.
2. Create a new issue to start a discussion around a new feature or a bug.
