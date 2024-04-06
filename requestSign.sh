echo -n "Enter keystore's password:"
read -s pwd
rpc="http://127.0.0.1:5871"
pubkey="be79a396f631627778be1eb285c0d7d21a71cf001a57bacdaf386245d8b6b43a"
gid="346b74be6df72662d7606d582f1a70e0bf29ff23de476eda1b46f98487bb032e8850571ae726fcc27b0e52f35291365c4b669354aed8b13b4d0507fdb1289fdd"
./gsmpc-client -cmd SIGN --keystore ./keystore --passwd $pwd -ts 3/5 -gid $gid -mode 0 -n 1 -loop 1 --url $rpc --keytype ED25519 -pubkey $pubkey -msghash $1
