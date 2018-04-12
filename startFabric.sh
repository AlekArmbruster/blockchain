#!/bin/bash
set -e

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1
starttime=$(date +%s)
CC_SRC_PATH=/opt/gopath/src/github.com/dogs/node

# clear docker
# docker rm -f $(docker ps -aq)
# docker network prune
# docker rmi dev-peer0.org1.example.com-dgchaincode-1.0-d530af5210349cb1c4dbcf073b594456cb96775dfe7f8d72665a1d5231d49ee8

# clean the keystore
rm -rf ./hfc-key-store

set -ev

# launch network; create channel and join peer to channel
docker-compose -f docker-compose-cli.yaml down --volumes
docker-compose -f docker-compose-cli.yaml down
docker-compose -f docker-compose-cli.yaml up -d
# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
# export FABRIC_START_TIMEOUT=10
# #echo ${FABRIC_START_TIMEOUT}
# sleep ${FABRIC_START_TIMEOUT}

# Create the channel
# docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel create -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/channel.tx


# Fali nam kreiranje kanala i join-ovanje peer-a kanalu,
# to treba naknadno dodati

# install, instantiate chaincode
# and prime the ledger with our 10 cars