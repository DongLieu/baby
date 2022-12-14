#!/bin/bash
rm -rf $HOME/.baby/
killall screen
killall babyd

KEY="test"
KEYRING="test"
CHAINID="toddler"
MONIKER="localtestnet"
KEYALGO="secp256k1"
LOGLEVEL="info"

BALANCE_1="1000000000ubaby"
BALANCE_2="50000000ubaby"
VALIDATOR_1="hieule1"
VALIDATOR_2="hieule2"
VALIDATOR_3="hieule3"

# config chain
babyd config keyring-backend $KEYRING
babyd config chain-id $CHAINID

# determine if user wants to recorver or create new
babyd keys add $KEY --keyring-backend $KEYRING --algo $KEYALGO
babyd keys add $VALIDATOR_1 --keyring-backend $KEYRING --algo $KEYALGO
babyd keys add $VALIDATOR_2 --keyring-backend $KEYRING --algo $KEYALGO
babyd keys add $VALIDATOR_3 --keyring-backend $KEYRING --algo $KEYALGO
# Initialize chain
babyd init $MONIKER --chain-id $CHAINID

# change staking denom to ubaby
cat $HOME/.baby/config/genesis.json | jq '.app_state["staking"]["params"]["bond_denom"]="ubaby"' > $HOME/.baby/config/tmp_genesis.json && mv $HOME/.baby/config/tmp_genesis.json $HOME/.baby/config/genesis.json
cat $HOME/.baby/config/genesis.json | jq '.app_state["crisis"]["constant_fee"]["denom"]="ubaby"' > $HOME/.baby/config/tmp_genesis.json && mv $HOME/.baby/config/tmp_genesis.json $HOME/.baby/config/genesis.json
cat $HOME/.baby/config/genesis.json | jq '.app_state["gov"]["deposit_params"]["min_deposit"][0]["denom"]="ubaby"' > $HOME/.baby/config/tmp_genesis.json && mv $HOME/.baby/config/tmp_genesis.json $HOME/.baby/config/genesis.json
cat $HOME/.baby/config/genesis.json | jq '.app_state["mint"]["params"]["mint_denom"]="ubaby"' > $HOME/.baby/config/tmp_genesis.json && mv $HOME/.baby/config/tmp_genesis.json $HOME/.baby/config/genesis.json

# api listen address: tcp://0.0.0.0:1350
sed -i -E 's|tcp://0.0.0.0:1317|tcp://0.0.0.0:1350|g' $HOME/.baby/config/app.toml
sed -i -E 's|swagger = false|swagger = true|g' $HOME/.baby/config/app.toml
sed -i -E 's|enable = false|enable = true|g' $HOME/.baby/config/app.toml

# Allocate genesis accounts (cosmos formatted addresses)
babyd add-genesis-account $KEY 1000000000000000ubaby --keyring-backend $KEYRING

babyd add-genesis-account $VALIDATOR_1 100000000000000ubaby --keyring-backend $KEYRING

babyd add-genesis-account $VALIDATOR_2 100000000000000ubaby --keyring-backend $KEYRING

babyd add-genesis-account $VALIDATOR_3 100000000000000ubaby --keyring-backend $KEYRING

# Sign genesis transaction
babyd gentx $KEY 1000000ubaby --keyring-backend $KEYRING --chain-id $CHAINID

# babyd gentx $VALIDATOR_1 1000000ubaby --keyring-backend $KEYRING --chain-id $CHAINID
# 
# babyd gentx $VALIDATOR_2 1000000ubaby --keyring-backend $KEYRING --chain-id $CHAINID
# 
# babyd gentx $VALIDATOR_3 1000000ubaby --keyring-backend $KEYRING --chain-id $CHAINID

# Collect genesis tx
babyd collect-gentxs

# Run this to ensure everything worked and that the genesis file is setup correctly
babyd validate-genesis

babyd keys list

# Start the node (remove the --pruning=nothing flag if historical queries are not needed)
#rpc listen address: tcp://0.0.0.0:1711
screen -S validator1 -d -m babyd start --pruning=nothing \
    --log_level $LOGLEVEL \
    --minimum-gas-prices=0.0001ubaby \
    --p2p.laddr tcp://0.0.0.0:1700 \
    --rpc.laddr tcp://0.0.0.0:1711 \
    --grpc.address 0.0.0.0:1701 \
    --grpc-web.address 0.0.0.0:1702

sleep 10

#get addresses of main wallet and accounts
KEY_ADDRESS=$(babyd keys show $KEY -a)
VALIDATOR1_ADDRESS=$(babyd keys show $VALIDATOR_1 -a)
VALIDATOR2_ADDRESS=$(babyd keys show $VALIDATOR_2 -a)
VALIDATOR3_ADDRESS=$(babyd keys show $VALIDATOR_3 -a)

echo $KEY_ADDRESS;
echo $VALIDATOR1_ADDRESS;
echo $VALIDATOR2_ADDRESS;
echo $VALIDATOR3_ADDRESS;

babyd q bank balances $KEY_ADDRESS --node tcp://0.0.0.0:1711
babyd q bank balances $VALIDATOR1_ADDRESS --node tcp://0.0.0.0:1711
babyd q bank balances $VALIDATOR2_ADDRESS --node tcp://0.0.0.0:1711
babyd q bank balances $VALIDATOR3_ADDRESS --node tcp://0.0.0.0:1711

#Transmit tokens
babyd tx bank send $KEY_ADDRESS $VALIDATOR1_ADDRESS $BALANCE_1 --chain-id $CHAINID --node tcp://0.0.0.0:1711 --gas auto --fees 10ubaby -y --keyring-backend=$KEYRING
sleep 5

babyd tx bank send $KEY_ADDRESS $VALIDATOR2_ADDRESS $BALANCE_1 --chain-id $CHAINID --node tcp://0.0.0.0:1711 --gas auto --fees 10ubaby -y --keyring-backend=$KEYRING
sleep 5

babyd tx bank send $KEY_ADDRESS $VALIDATOR3_ADDRESS $BALANCE_2 --chain-id $CHAINID --node tcp://0.0.0.0:1711 --gas auto --fees 10ubaby -y --keyring-backend=$KEYRING
sleep 5

sleep 10

babyd q bank balances $VALIDATOR1_ADDRESS --node tcp://0.0.0.0:1711
babyd q bank balances $VALIDATOR2_ADDRESS --node tcp://0.0.0.0:1711
babyd q bank balances $VALIDATOR3_ADDRESS --node tcp://0.0.0.0:1711