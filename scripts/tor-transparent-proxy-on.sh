# shellcheck disable=SC2154
# Variables nft_cmd and id_cmd are set by the Nix wrapper.

# Install nftables rules that redirect all outbound TCP through Tor's
# TransPort (127.0.0.1:9040) and all DNS through Tor's DNSPort
# (127.0.0.1:5353).  The rules live in a dedicated table
# (tor-transparent-proxy) so they can be removed cleanly without
# affecting the NixOS firewall.

TOR_UID=$("$id_cmd" -u tor)
TRANS_PORT=9040
DNS_PORT=5353

# IPv4 NAT and filter rules
"$nft_cmd" -f - <<EOF
table ip tor-transparent-proxy {
  chain nat-output {
    type nat hook output priority -100; policy accept;

    # Let Tor itself reach the real internet (prevent routing loops)
    meta skuid $TOR_UID accept

    # Skip loopback and LAN ranges
    ip daddr 127.0.0.0/8 accept
    ip daddr 10.0.0.0/8 accept
    ip daddr 172.16.0.0/12 accept
    ip daddr 192.168.0.0/16 accept

    # Redirect all remaining TCP to Tor TransPort
    tcp dport 1-65535 redirect to :$TRANS_PORT

    # Redirect DNS (UDP 53) to Tor DNSPort
    udp dport 53 redirect to :$DNS_PORT
  }

  chain filter-output {
    type filter hook output priority 0; policy accept;

    # Allow established/related connections
    ct state established,related accept

    # Allow Tor's own traffic
    meta skuid $TOR_UID accept

    # Allow loopback
    oifname "lo" accept

    # Allow LAN
    ip daddr 10.0.0.0/8 accept
    ip daddr 172.16.0.0/12 accept
    ip daddr 192.168.0.0/16 accept

    # Drop anything else that somehow bypassed NAT
    tcp dport 1-65535 drop
    udp dport 1-65535 drop
  }
}
EOF

# IPv6: block all non-loopback outbound (Tor does not support IPv6 exit)
"$nft_cmd" -f - <<EOF
table ip6 tor-transparent-proxy {
  chain filter-output {
    type filter hook output priority 0; policy accept;

    # Allow loopback
    oifname "lo" accept

    # Drop everything else
    drop
  }
}
EOF

echo "Tor transparent proxy enabled"
