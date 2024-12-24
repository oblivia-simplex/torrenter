#! /usr/bin/env bash

export rlog=/logs/route.txt
:> $rlog

function logroute() {
	ip route >> $rlog
	echo '=======================================' >> $rlog
}

logroute

openvpn --daemon --config /vpn/default.ovpn
echo "Waiting for openvpn to start..."

while ! ( ip route | grep '^0\.0\.0\.0/1 .*tun'); do
	sleep 1
done

sleep 10

logroute

## Now fix the routing table

# get the vpn gateway ip address and device
read -r vip vdev < <(ip route | awk '/0\.0\.0\.0\/1/ { print $3, $5 }')
# make sure vdev starts with 'tun'
if [ "${vdev:0:3}" != "tun" ]; then
  echo "Error: Gateway device is not tun*"
  exit 1
fi 

# get the default gateway ip address and device
read -r gip gdev < <(ip route | awk '/default/ { print $3, $5 }')

echo "[-] vpn gateway: $vip $vdev" | tee -a $rlog
echo "[-] default gateway: $gip $gdev" | tee -a $rlog



# get the docker subnet
dockernet=$(ip addr show dev docker0 | grep -oP "(?<=inet )[0-9./]+")

# temporarily delete the vpn routing rule
ip route del 0.0.0.0/1
# now add the vpn route with a higher cost
ip route add 0.0.0.0/1 metric 9999 via "$vip" dev "$vdev"
# That should do it!

# Set up the firewall rules to ensure only the tun interface is used
iptables -I OUTPUT ! -o "$vdev" -m owner --uid-owner openvpn -j DROP
iptables -I OUTPUT -o "$vdev" -j ACCEPT
iptables -I OUTPUT -o lo -j ACCEPT
iptables -I OUTPUT -d "$dockernet" -j ACCEPT
iptables -P OUTPUT DROP

echo "[+] Firewall rules set to enforce tun interface usage." | tee -a $rlog

iptables -L -v -n | tee -a $rlog

echo "=======================================" >> $rlog

logroute

echo -e "vip = $vip\nvdev = $vdev\ngip = $gip\ngdev = $gdev" >> $rlog

echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Start a background watchdog process
(
  while true ; do
    if ! ip route | grep -q "^0\.0\.0\.0/1 .*${vdev}"; then
      echo "Tunnel interface $vdev is down. Exiting." | tee -a $rlog
      pkill -SIGTERM -P $$ # Terminate all processes in the script's process group
      exit 1
    fi
    sleep 1
  done
) 
