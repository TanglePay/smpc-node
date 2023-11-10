# Introduction
This is an implementation of multi-party threshold ECDSA (elliptic curve digital signature algorithm) based on [GG20: One Round Threshold ECDSA with Identifiable Abort](https://eprint.iacr.org/2020/540.pdf) and eddsa (Edwards curve digital signature algorithm),including the implementation of approval list connected with upper layer business logic and channel broadcasting based on P2P protocol.

It includes three main functions:

(1) Key generation is used to create secret sharing ("keygen") without trusted dealers.

(2) Use secret sharing,Paillier encryption and decryption to generate a signature ("signing").

(3) Preprocessing data before generating signature.(“pre-sign”).

When issuing the keygen/signing request command, there are two modes to choose from:

(1) Each participant node needs to approve the request command with its own account.It will first get the request command from the local approval list, and then approve or disagree.

(2) Each participant node does not need to approve the request command,which is agreed by default.

In distributed computing,message communication is required between each participant node.Firstly,the selected participants will form a group,and then P2P communication will be carried out within the group to exchange the intermediate calculation results of FastMPC algorithm.

The implementation is mainly developed in golang language,with a small amount of shell and C language.Leveldb database is used for local data storage,and third-party library codes such as Ethereum source code P2P and RPC modules and golang crypto are cited.

The implementation provides a series of RPC interfaces for external applications,such as bridge / router,to call in an RPC driven manner.The external application initiates a keygen/signaling request(RPC call),and then calls another RPC interface to obtain the approval list for approval.When the distributed calculation is completed,it will continue to call the RPC interface to obtain the calculation results.


# Install from code
# Prerequisites
1. VPS server with 1 CPU and 2G mem
2. Static public IP
3. Golang ^1.12

# Setting Up
## Clone The Repository
To get started, launch your terminal and download the latest version of the SDK.
```
git clone https://github.com/TanglePay/smpc-node.git
```
## Build
Next compile the code. Make sure you are in tanglepay-smpc directory.
```
cd tanglepay-smpc && make all
```

## Run By Default BootNode And Parametes
run the smpc node in the background:
```
nohup ./build/bin/gsmpc &
```
The `gsmpc` will provide rpc service, the default RPC port is port 4449.

## Manually Set Parameter To Run Node And Self-test 
1. Start bootnode and get the bootnode key that will be used for parameter --bootnodes
```shell
./build/bin/bootnode --genkey=boot.key
nohup ./bootnode --nodekey=boot.key > boot.log 2>&1  &
```
2. Start 3 mpc nodes
```shell
nohup ./gsmpc --rpcport 5871 --bootnodes "enode://cf1dfd1bd276738af39fe9dae02680b2a60e8750590df08d1e61ec1b41a5085eadbb95b6a79cbd1b83b682383bb1a1ebae9d9369e99fd5725e1d736f3857180b@127.0.0.1:4440" --port 48541 --nodekey "node1.key" --verbosity 5 > node1.log 2>&1 &

nohup ./gsmpc --rpcport 5872 --bootnodes "enode://cf1dfd1bd276738af39fe9dae02680b2a60e8750590df08d1e61ec1b41a5085eadbb95b6a79cbd1b83b682383bb1a1ebae9d9369e99fd5725e1d736f3857180b@127.0.0.1:4440" --port 48542 --nodekey "node2.key" --verbosity 5 > node2.log 2>&1 &

nohup ./gsmpc --rpcport 5873 --bootnodes "enode://cf1dfd1bd276738af39fe9dae02680b2a60e8750590df08d1e61ec1b41a5085eadbb95b6a79cbd1b83b682383bb1a1ebae9d9369e99fd5725e1d736f3857180b@127.0.0.1:4440" --port 48543 --nodekey "node3.key" --verbosity 5 > node3.log 2>&1 &
```
3. Create group id containing 3 nodes
```shell
./gsmpc-client -cmd SetGroup -url http://127.0.0.1:5871 --keystore ./keystore1 --passwd yourpassword -ts 2/3 -node http://127.0.0.1:5871 -node http://127.0.0.1:5872 -node http://127.0.0.1:5873 -node http://127.0.0.1:5874 -node http://127.0.0.1:5875
Gid = 9b57a395e12b4a70a44c352bb297189b798eae68de0c9744f16c3f0ef73992745c847160728b2f8b289657ab431ca8f5f367976df821fba6725ca22221c66f58
```
4. Create a subgroup id (select node 1, 2 as example)
```shell
./gsmpc-client -cmd SetGroup -url http://127.0.0.1:5871 --keystore ./keystore1 --passwd yourpassword -ts 2/3 -node http://127.0.0.1:5871 -node http://127.0.0.1:5872
Gid = e7fd1f3b48865f158dbccfcbc7d2af7ac7cab0783726ce43b0724b96cf83a8632cc637f6da880f06c4bb246b23fb96e0ef9a33b8dde72df7d1108294bf1aa33f
```
5. Get the sign information from each node
sign infomation is: EnodeID@IP:PORT + hex.EncodeToString(crypto.Sign(crypto.Keccak256(EnodeID), privateKey))
```shell
./gsmpc-client -cmd EnodeSig -url http://127.0.0.1:5871 --keystore ./keystore1 --passwd yourpassword
./gsmpc-client -cmd EnodeSig -url http://127.0.0.1:5872 --keystore ./keystore2 --passwd yourpassword
./gsmpc-client -cmd EnodeSig -url http://127.0.0.1:5873 --keystore ./keystore3 --passwd yourpassword
```
6. Request for generating public key
* gid is the group id containing 3 nodes.
* keytype: EC256K1 or ED25519 or EC256STARK.
* sig is the sign information of node.
* mode: 0 co-management mode or 1 non-co-management mode or 2 random signature subgroup mode
* there is a pause to wait for `ACCEPTREQADDR` in the step 7.
```shell
./gsmpc-client -cmd REQSMPCADDR --keystore ./keystore1 --passwd yourpassword -gid 9b57a395e12b4a70a44c352bb297189b798eae68de0c9744f16c3f0ef73992745c847160728b2f8b289657ab431ca8f5f367976df821fba6725ca22221c66f58 -mode 0 -url http://127.0.0.1:5871 --keytype ED25519 -sig enode://6f96601d34d03066ed0305ec6b3932d42f8212af6e3d7247d34cff830c13503288b22558822e7e00d1f343cf9685baf697cd41d6c2ca64c0205017d72bf698bc@127.0.0.1:485410x576f92946db81e9354df4b4ead196e58639e267ebbeca2c1f93ea14ada759927624f5a92d00157d8d1bce5edc68f1734cf4219a98cd851969a86f99b5cc1ce1401 -sig enode://8545294fac4a28fa47d25e1372e63c737af9e728e3244e05f3c540ab0d6f052d53affd3b3dcb83c9614efe98f2f80b5deb4022f493a2e1d9b8d9fb4d91e2b8d7@127.0.0.1:485420x7456e6e7e62f2ef68251f0ea608f92cdee63d015ab1e75214bb0e0592c6aff147efcc7082228bc574ebf4ab179ec64b67abbb4a56fb6f4c3f3533afe328f71d701 -sig enode://8a7f688882cd293f490d0ad099e3becf3bb99d936b2f29199233c3c49884814bd73f5fcfec63372d76c112c3e8287b381501efe309a7b99f76db3a589fe6aa0d@127.0.0.1:485430x8e7239d77c8abf28d186c6bf1524d2f84c2c8cc47d03b41d6e64192bf05104811e499ce92ddb61020832ab0026e415348d70a9f0b88d7b129cf38e5450b4b4a101
```
7. Accept the request of generating public key
* key is the unique ID of this request command and is obtained in step 6.
```shell
./gsmpc-client -cmd ACCEPTREQADDR  -url http://127.0.0.1:5871 --keystore ./keystore1 --passwd yourpassword -key 0x86d65aa75c116279a19ed845c2ff188bcbac410c5e419e500c864685c04c0459 --keytype ED25519 -mode 0
./gsmpc-client -cmd ACCEPTREQADDR  -url http://127.0.0.1:5872 --keystore ./keystore2 --passwd yourpassword -key 0x86d65aa75c116279a19ed845c2ff188bcbac410c5e419e500c864685c04c0459 --keytype ED25519 -mode 0
./gsmpc-client -cmd ACCEPTREQADDR  -url http://127.0.0.1:5873 --keystore ./keystore3 --passwd yourpassword -key 0x86d65aa75c116279a19ed845c2ff188bcbac410c5e419e500c864685c04c0459 --keytype ED25519 -mode 0
```
8. Pre-generated sign data
* mode = 2 does not need to be pre generated or automatically pre generated. Other mode values need to do this.
* if ed, skip this step.
* select node 1,2 as example.
* pubkey is the public key obtained in step 7.
```shell
./gsmpc-client -cmd PRESIGNDATA --keystore ./keystore1 --passwd yourpassword -pubkey  047781b557b4cb160429cf9f36eda0a90d49ac2711bdff62a5113c15faaea57ee5659cfeef1b276e234b47097d413a65380f50bc1e67ea94f0665d74949c4a23ab -subgid e7fd1f3b48865f158dbccfcbc7d2af7ac7cab0783726ce43b0724b96cf83a8632cc637f6da880f06c4bb246b23fb96e0ef9a33b8dde72df7d1108294bf1aa33f  -url  http://127.0.0.1:5871 -mode 0
```
9. Sign
* gid is the subgroup id, and pubkey is the public key obtained in step 7.
* msghash is the hash to be signed, can be plural.
* msgcontext is the information of the cross-chain bridge, you can just ignore this default.
* keytype: EC256K1 or ED25519 or EC256STARK.
* select node 1,2 as example.
```shell
./gsmpc-client -cmd SIGN --keystore ./keystore1 --passwd yourpassword -ts 2/3 -n 1 --loop 1 -gid e7fd1f3b48865f158dbccfcbc7d2af7ac7cab0783726ce43b0724b96cf83a8632cc637f6da880f06c4bb246b23fb96e0ef9a33b8dde72df7d1108294bf1aa33f -mode 0 --url http://127.0.0.1:5871 --keytype EC256K1 -pubkey 047781b557b4cb160429cf9f36eda0a90d49ac2711bdff62a5113c15faaea57ee5659cfeef1b276e234b47097d413a65380f50bc1e67ea94f0665d74949c4a23ab -msghash 0x90e032be062dd0dc689fa23df8c044936a2478cb602b292c7397354238a67d88  -msgcontext '{"swapInfo":{"swapid":"0x4f62545cdd05cc346c75bb42f685a18a02621e91512e0806eac528d0b2f6aa5f","swaptype":1,"bind":"0x0520e8e5e08169c4dbc1580dc9bf56638532773a","identifier":"ssUSDT2FSN"},"extra":{"ethExtra":{"gas":90000,"gasPrice":1000000000,"nonce":1}}}'

./gsmpc-client -cmd SIGN --keystore ./keystore2 --passwd yourpassword -ts 2/3 -n 1 --loop 2 -gid e7fd1f3b48865f158dbccfcbc7d2af7ac7cab0783726ce43b0724b96cf83a8632cc637f6da880f06c4bb246b23fb96e0ef9a33b8dde72df7d1108294bf1aa33f -mode 0 --url http://127.0.0.1:5872 --keytype EC256K1 -pubkey 047781b557b4cb160429cf9f36eda0a90d49ac2711bdff62a5113c15faaea57ee5659cfeef1b276e234b47097d413a65380f50bc1e67ea94f0665d74949c4a23ab -msghash 0x90e032be062dd0dc689fa23df8c044936a2478cb602b292c7397354238a67d88  -msgcontext '{"swapInfo":{"swapid":"0x4f62545cdd05cc346c75bb42f685a18a02621e91512e0806eac528d0b2f6aa5f","swaptype":1,"bind":"0x0520e8e5e08169c4dbc1580dc9bf56638532773a","identifier":"ssUSDT2FSN"},"extra":{"ethExtra":{"gas":90000,"gasPrice":1000000000,"nonce":1}}}'
```
10. Let the nodes in the subgroup agree to sign
* key is the unique ID of this sign request command and is obtained in step 9.
```shell
./gsmpc-client -cmd ACCEPTSIGN  -url http://127.0.0.1:5871 --keystore ./keystore1 --passwd yourpassword -key 0x5cdbe2981c399336952dee62ee3120674c18fb68a7965c9664a5e4bbcc96b589 --keytype EC256K1 -mode 0

./gsmpc-client  -cmd ACCEPTSIGN -url http://127.0.0.1:5872 --keystore ./keystore2 --passwd yourpassword -key 0x5cdbe2981c399336952dee62ee3120674c18fb68a7965c9664a5e4bbcc96b589 --keytype EC256K1 -mode 0
```

## Local Test
It will take some time more than 15 minutes,please wait patiently!
```
make gsmpc-test
```

#Note

1.If you want to call RPC API, please wait at least 2 minutes after running the node.

2.If you want to call RPC API quickly more than once,please wait longer.

3.If you want to reboot a node, please wait 2 minute after closing node before restarting the node.
