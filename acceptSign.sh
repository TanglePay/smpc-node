echo -n "Enter keystore's password:"
read -s pwd
rpc="http://127.0.0.1:5871"
./gsmpc-client -cmd ACCEPTSIGN -url $rpc --keystore ./keystores/smpc_k --passwd $pwd -key $1 --keytype ED25519 -mode 0
