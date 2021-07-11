#!/bin/bash

gretap_up () {
    echo "add veth pair veth1-1, veth1-2"
    ip l add name veth1-1 type veth peer name veth1-2
    
    echo "configure veth1-1"
    ip a add 10.10.16.1/30 broadcast 10.10.16.3 dev veth1-1
    sysctl -w net.ipv6.conf.veth1-1.disable_ipv6=1
    ip l set dev veth1-1 mtu 1420
    ip l set dev veth1-1 up

    echo "create netns nstest"
    ip netns add nstest
    ip l set dev veth1-2 netns nstest

    echo "netns: cconfigure"
    ip netns exec nstest ip l set dev lo up
    ip netns exec nstest ip a add 10.10.16.2/30 broadcast 10.10.16.3 dev veth1-2
    ip netns exec nstest sysctl -w net.ipv6.conf.veth1-2.disable_ipv6=1
    ip netns exec nstest ip l set dev veth1-2 mtu 1420
    ip netns exec nstest ip l set dev veth1-2 up


    echo "nstest: create gretap tunnel"
    ip netns exec nstest ip l add name gretap1 type gretap local 10.10.16.2 remote 10.10.16.1 nopmtudisc #ignore-df nopmtudisc
    ip netns exec nstest ip a add 172.31.16.2/24 broadcast 172.31.16.255 dev gretap1
    ip netns exec nstest ip a add fddd:200:200::2/64 dev gretap1
    #ip netns exec nstest ip l set dev gretap1 mtu 1462
    ip netns exec nstest ip l set dev gretap1 up


    echo "create gretap tunnel"
    ip l add name gretap1 type gretap local 10.10.16.1 remote 10.10.16.2 nopmtudisc #ignore-df nopmtudisc
    ip a add 172.31.16.1/24 broadcast 172.31.16.255 dev gretap1
    ip a add fddd:200:200::1/64 dev gretap1
    #ip l set dev gretap1 mtu 1462
    ip l set dev gretap1 up

}


gretap_down () {
    ip l del dev gretap1
    ip l del dev veth1-1
    #ip l del veth1-2
    ip netns del nstest
}


if [[ "$1" == "up" ]]; then
  gretap_up
elif [[ "$1" == "down" ]];   then
  gretap_down
else
  echo "up/down"
fi
