# shellcheck disable=SC2154
# Variable nft_cmd is set by the Nix wrapper.

# Remove the tor-transparent-proxy nftables table (both ip and ip6
# families), restoring normal routing.

"$nft_cmd" delete table ip tor-transparent-proxy 2>/dev/null || true
"$nft_cmd" delete table ip6 tor-transparent-proxy 2>/dev/null || true

echo "Tor transparent proxy disabled"
