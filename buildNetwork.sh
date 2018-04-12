#!/bin/bash
# MODE=$1;shift Ovo bi nam trebalo da saljeno recimo up ili down pa da na osnovu toga on nesto radi

# clean the keystore
rm -rf ./hfc-key-store

# timeout duration - the duration the CLI should wait for a response from
# another container before giving up
CLI_TIMEOUT=10
# default for delay between commands
CLI_DELAY=3
# channel name defaults to "mychannel"
CHANNEL_NAME="mychannel"
# use this as the default docker-compose yaml definition
COMPOSE_FILE=docker-compose-cli.yaml
#
COMPOSE_FILE_COUCH=docker-compose-couch.yaml
# use golang as the default language for chaincode
LANGUAGE=node
# default image tag
IMAGETAG="latest"
# 
COMPOSE_FILE_CA=docker-compose-ca.yaml

export FABRIC_CFG_PATH=$PWD

# GENERATE CERTS
# Generates Org certs using cryptogen tool
which cryptogen
if [ "$?" -ne 0 ]; then
echo "cryptogen tool not found. exiting"
exit 1
fi
echo
echo "##########################################################"
echo "##### Generate certificates using cryptogen tool #########"
echo "##########################################################"

if [ -d "crypto-config" ]; then
rm -Rf crypto-config
fi
set -x
cryptogen generate --config=./crypto-config.yaml
res=$?
set +x
if [ $res -ne 0 ]; then
echo "Failed to generate certificates..."
exit 1
fi
echo





# REPLACE PRIVATE KEY
# Using docker-compose-ca-template.yaml, replace constants with private key file names
# generated by the cryptogen tool and output a docker-compose.yaml specific to this
# configuration

# sed on MacOSX does not support -i flag with a null extension. We will use
# 't' for our back-up's extension and depete it at the end of the function
ARCH=`uname -s | grep Darwin`
if [ "$ARCH" == "Darwin" ]; then
OPTS="-it"
else
OPTS="-i"
fi

# Copy the template to the file that will be modified to add the private key
cp docker-compose-ca-template.yaml docker-compose-ca.yaml

# The next steps will replace the template's contents with the
# actual values of the private key file names for the two CAs.
CURRENT_DIR=$PWD
cd crypto-config/peerOrganizations/org1.example.com/ca/
PRIV_KEY=$(ls *_sk)
cd "$CURRENT_DIR"
sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-ca.yaml
# If MacOSX, remove the temporary backup of the docker-compose file
if [ "$ARCH" == "Darwin" ]; then
rm docker-compose-ca.yamlt
fi




# GENERATE CHANNEL ARTIFACTS
# Generate orderer genesis block, channel configuration transaction and
# anchor peer update transactions
which configtxgen
if [ "$?" -ne 0 ]; then
echo "configtxgen tool not found. exiting"
exit 1
fi

echo "##########################################################"
echo "#########  Generating Orderer Genesis block ##############"
echo "##########################################################"
# Note: For some unknown reason (at least for now) the block file can't be
# named orderer.genesis.block or the orderer will fail to launch!
set -x
configtxgen -profile OneOrgOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
res=$?
set +x
if [ $res -ne 0 ]; then
echo "Failed to generate orderer genesis block..."
exit 1
fi
echo
echo "#################################################################"
echo "### Generating channel configuration transaction 'channel.tx' ###"
echo "#################################################################"
set -x
configtxgen -profile OneOrgChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
res=$?
set +x
if [ $res -ne 0 ]; then
echo "Failed to generate channel configuration transaction..."
exit 1
fi

echo
echo "#################################################################"
echo "#######    Generating anchor peer update for Org1MSP   ##########"
echo "#################################################################"
set -x
configtxgen -profile OneOrgChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP
res=$?
set +x
if [ $res -ne 0 ]; then
echo "Failed to generate anchor peer update for Org1MSP..."
exit 1
fi




# Prodji kroz ova 3 fajla i postavi mrezu i kontejnere na docker-u
IMAGE_TAG=$IMAGETAG docker-compose -f $COMPOSE_FILE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_CA up -d 2>&1
# IMAGE_TAG=$IMAGETAG docker-compose -f $COMPOSE_FILE_CA up -d

if [ $? -ne 0 ]; then
echo "ERROR !!!! Unable to start network"
exit 1
fi


# now run the end to end script
docker exec cli scripts/script.sh $CHANNEL_NAME $CLI_DELAY $LANGUAGE $CLI_TIMEOUT
if [ $? -ne 0 ]; then
echo "ERROR !!!! Test failed"
exit 1
fi



echo "#################################################################"
echo "#######    FINISH   ##########"
echo "#################################################################"