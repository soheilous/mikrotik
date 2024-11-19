# shellcheck disable=SC2148

# Add DHCP Client for modems
#? replace interface name with yours (ether1, ether2, ether3...)
/ip/dhcp-client/add interface=NAME add-default-route=no

# Add address for local lan network - `192.168.88.1/24` is the default from the Mikrotik
/ip/address/add address=192.168.88.1/24 interface=ether5

#! Add DHCP Server, so clients can get IP automatically
/ip/pool/add name=dhcp_pool0 ranges=192.168.88.2-192.168.88.254
/ip/dhcp-server/network/add address=192.168.88.0/24 gateway=192.168.88.1 dns-server=8.8.8.8,8.8.4.4
/ip/dhcp-server/add name=dhcp1 interface=ether5 lease-time=3d address-pool=dhcp_pool0

#! Add routes for each modems according to addresses
:local dhcpRawIP [/ip address get [find interface=ether2] network];:local dhcpIP [:pick $dhcpRawIP 0 [:find $dhcpRawIP "/"]];/ip route add dst-address=0.0.0.0/0 gateway=$dhcpIP

#! Add NAT for access clients to internet
interface/list/add name=internet
# Add all modems interfaces to the `internet` list - NAME is the modems interface name
interface/list/member/add list=internet interface=NAME
# Add NAT for access interfaces to the internet
ip/firewall/nat/add chain=srcnat out-interface-list=internet action=masquerade

#! ********    load balancing    ********
# Add list `internet` for NAT purposes


# Add marks for all modem interfaces
routing/table/add name=NAME fib

# Mark interfaces - INTERFACE_NAME is the modems interface name
ip/firewall/mangle/add chain=prerouting in-interface=INTERFACE_NAME action=mark-routing connection-mark=no-mark new-routing-mark=NAME

# Load balance with PCC - INTERFACE_NAME is the lan - # TODO: X/Y 
ip/firewall/mangle/add chain=prerouting in-interface=INTERFACE_NAME connection-mark=no-mark dst-address-type=!local per-connection-classifier=both-addresses-and-ports:X/Y action=mark-connection new-connection-mark=NAME

# INTERFACE_NAME is the lan - CONN_MARK is modem mark name - ROUTE_MARK is modem mark name
ip/firewall/mangle/add chain=prerouting in-interface=INTERFACE_NAME connection-mark=CONN_MARK action=mark-routing new-routing-mark=ROUTE_MARK

# Add output markers to modems interfaces - CONN_MARK is modem mark name - ROUTE_MARK is modem mark name
ip/firewall/mangle/add chain=output connection-mark=CONN_MARK action=mark-routing new-routing-mark=ROUTE_MARK

# Add route for marked connections - ROUTE_MARK is modem mark name
ip/route/add gateway=MODEM_IP+1 routing-table=ROUTE_MARK check-gateway=ping
#! ********    load balancing    ********


# Continue of failover

# TODO: Add comment command for routes with dst-address: 0.0.0.0/0 and gateway:MODEM_IP with empty routing mark

# FIXME: Merge up and down script
# Add net-watch with different host for automatically switch off routes with high ping or unavailability - NAME is netwatch name
tool/netwatch/add name=NAME host=4.2.2.4 interval=3s timeout=500ms down-script="ip route disable [find comment=ROUTE_COMMENT]"
tool/netwatch/add name=NAME host=4.2.2.4 interval=3s timeout=500ms up-script="ip route enable [find comment=ROUTE_COMMENT]"

# Add routes for net-watch
ip/route/add dst-address=NET_WATCH_HOST gateway=MODEM_IP check-gateway=ping