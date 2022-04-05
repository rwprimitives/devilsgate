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


### Configure Gatekeeper

A Raspberry PI can be configured as a **gatekeeper** by using the `-c` option. By default, the Tor exit country is set to `US`. However, you can specify a country code after the `-c` option. See the example below:

    # Configure a gatekeeper to exit out of Canada
    ./devilsgate.sh -c ca


### Query Country Information

Remembering two letter country codes is hard. So **devilsgate** makes it easier on you by providing a way to query for any country given a keyword. It will print out any country that contains that keyword and hopefully the result will contain the desired output.

For example, I need the two letter country code for Bulgaria and I don't know how to spell Bulgaria but I know it starts with `bul`. You can use **devilsgate** and search for `bul` as such:

    ./devilsgate.sh -q bul
    [+] Searching for the following keyword(s): bul
        [BG] Bulgaria
    [+] Search complete!
    [!] Not all countries contain Tor exit relays!

As you can see the result above, **devilsgate** found a match that contained the keyword 'bul'. However, notice the warning message indicating that not all countries contain Tor exit relays. To find out if a country contains Tor exit relays, use [torseeker](https://github.com/rwprimitives/tor-seeker) to perform a query on the desired country.


### Set Tor Exit Country

**devilsgate** can be used to change the Tor exit country with the `-s` option followed by the desired country code, as such:

    # Change the Tor exit country to Brazil
    ./devilsgate.sh -s br


### Restart Tor Service

**devilsgate** allows you to restart the Tor service if necessary with the `-r` option, as such:

    ./devilsgate.sh -r


### Test Connection

**devilsgate** provides a way to test if you have an active connection to the Tor network by using the `-t` option. It is highly suggested that after changing the Tor exit country to verify that there is still an active connection. Not all countries contain active Tor exit relays, so it is possible that you may lose connection to the Tor network.

    ./devilsgate.sh -t


## TROUBLESHOOTING

This sections provides solutions on commonly seen problems.


### No DNS Resolution After Configuration

After configuring a Raspberry PI as a **gatekeeper**, you must reboot in order for all the changes to apply. However, after rebooting sometimes a `client` connected to **gatekeeper** may not be able to resolve DNS requests. It's possible that the Tor service is started and running but is not connected to the Tor network after a reboot. It takes time for the Tor service to connect to the Tor network, however sometimes it never connects.

Use **devilsgate** with the `-r` option to restart the Tor service, then use the `-t` option to test the Tor connection. If the test fails, then change the Tor exit country to another country that has Tor exit nodes. Keep in mind that not all countries have Tor exit nodes. If the test is successful, the `client` will be able to resolve DNS requests.


### No DNS Resolution After Reset

After resetting a **gatekeeper** back to a normal state, after reboot the Raspberry PI may not be able to resolve any DNS requests. You may need to provide some time for the Rasperry PI to communicate with your gateway and eventually it'll be able to resolve DNS requests through your network's gateway. If the problem still persists, try restart the `dhcpcd` service as such:

    systemctl restart dhcpcd

After restarting the `dhcpcd` service, wait a few seconds and try navigating to a website using the browser or via command line using `wget` or `curl` command line tools.


## DEVELOPMENT

**devilsgate** is analyzed with [shellcheck](https://github.com/koalaman/shellcheck) to ensure best practices are followed.

Testing was conducted on the following Raspberry PI OS versions:

1. Raspberry PI OS with Desktop 32-bit (bullseye)
2. Raspberry PI OS Lite 32-bit (bullseye)
3. Raspberry PI OS with Desktop 64-bit (bullseye)
4. Raspberry PI OS Lite 64-bit (bullseye)


All testing was done using the following Raspberry PI models:

1. Raspberry PI 3 Model B Plus Rev 1.3
2. Raspberry PI 4 Model B Rev 1.5


## CONTRIBUTIONS

Contributions to the project can be made by doing one of the following:

1. Check for open issues before submitting a feature or bug.
2. Create a new issue to start a discussion around a new feature or a bug.
