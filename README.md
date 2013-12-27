# LibreMap agent for openwrt

This is the [LibreMap](http://libremap.net) submit agent for routers that run openwrt. The agent gathers information about your router and sends it to a [LibreMap server](https://github.com/libremap/libremap-api) (you can run your own!).

## Installation
If your openwrt installation uses an opkg repository where the `libremap-agent` package is included then simply run
```bash
opkg update && opkg install libremap-agent
```
The plain `libremap-agent` package only uploads a minimal description of your router to a [LibreMap server](https://github.com/libremap/libremap-api) and you probably want to install some plugins that provide additional information (like community data, links of routing protocols like OLSR or batman-adv, ...). The following plugin packages are available:
* `luci-lib-libremap-contact` - Provide contact information of the router operator
* `luci-lib-libremap-location` - Provide latitude/longitude/elevation of the router
* `luci-lib-libremap-olsr` - Gathers links to OLSR neighbors (IPv4+IPv6) of the router
* `luci-lib-libremap-system` - Provide information about your router (hostname, hardware, memory)

## Compilation
TODO

## Development
Bug reports and feature requests should be filed as issues in this repository.

Feel free to extend the submit agent by enhancing an already available plugin or by writing a new one. We'd be happy to include your plugin in this repository - please file a pull request!
