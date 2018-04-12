#!/bin/bash

# clear docker
docker rm -f $(docker ps -aq)
docker network prune
docker rmi dev-peer0.org1.example.com-dgchaincode-1.0-d530af5210349cb1c4dbcf073b594456cb96775dfe7f8d72665a1d5231d49ee8