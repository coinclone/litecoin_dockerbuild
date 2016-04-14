#!/usr/bin/env bash

# Set veriables
DATA_TIMESTAMP=1422681363
NEW_DATA_TIMESTAMP=$(date +%s)
DATATESTNET_TIMESTAMP=1365458829
NEW_DATATESTNET_TIMESTAMP=$(expr $(date +%s) - 90)

MAIN_VALERTPUBKEY="040184710fa689ad5023690c80f3a49c8f13f8d45b8c857fbcbc8bc4a8e4d3eb4b10f4d4604fa08dce601aaf0f470216fe1b51850b4acf21b179c45070ac7b03a9"
TEST_VALERTPUBKEY="0449623fc74489a947c4b15d579115591add020e53b3490bf47297dfa3762250625f8ecc2fb4fc59f69bdce8f7080f3167808276ed2c79d297054367566038aa82"

SCRIPT_PUB_KEY="140184710fa689ad5023690c80f3a49c8f13f8d45b8c857fbcbc8bc4a8e4d3eb4b10f4d4604fa08dce601aaf0f470216fe1b51850b4acf21b179c45070ac7b03a9"

MAIN_GENESIS_NTIME=1317972665
TEST_GENESIS_NTIME=1317798646

MAINNET_MERKLE_ROOT="97ddfbbae6be97fd6cdf3e7ca13232a3afff2353e29badfab7f73011edd4ced9"

MAINNET_NONCE=2084524493
TESTNET_NONCE=385270584

MAINNET_GENESIS_HASH="12a765e31ffd4059bada1e25190f6e98c99d9714d334efa41a195a7e7e04bfe2"
TESTNET_GENESIS_HASH="f5ae71e26c74beacc88382716aced69cddf3dffff24f384e1808905e0188f68f"
REGTESTNET_GENESIS_HASH="530827f38f93b43ed12af0b3ad25a288dc02ed74d6d7857862df51fc56c416f9"

# Generate key pairs and convert to hex format
mkdir $HOME/key_files/
cd $HOME/key_files/
openssl ecparam -genkey -name secp256k1 -out alertkey.pem
openssl ec -in alertkey.pem -text > alertkey.hex
openssl ecparam -genkey -name secp256k1 -out testnetalert.pem
openssl ec -in testnetalert.pem -text > testnetalert.hex
openssl ecparam -genkey -name secp256k1 -out genesiscoinbase.pem
openssl ec -in testnetalert.pem -text > genesiscoinbase.hex
wait

# Update timestamps
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$DATA_TIMESTAMP/$NEW_DATA_TIMESTAMP/g"
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$DATATESTNET_TIMESTAMP/$NEW_DATATESTNET_TIMESTAMP/g"
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$MAIN_GENESIS_NTIME/$NEW_DATA_TIMESTAMP/g"
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$TEST_GENESIS_NTIME/$NEW_DATATESTNET_TIMESTAMP/g"

# Update alert keys
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$MAIN_VALERTPUBKEY/$(python $HOME/get_pub_key.py $HOME/key_files/alertkey.hex)/g"
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$TEST_VALERTPUBKEY/$(python $HOME/get_pub_key.py $HOME/key_files/testnetalert.hex)/g"

# Update script pub key
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$SCRIPT_PUB_KEY/$(python $HOME/get_pub_key.py $HOME/key_files/genesiscoinbase.hex)/g"

# Update magic bytes
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/pchMessageStart\[0\] =/pchMessageStart\[0\] = 0x$(printf "%x\n" $(shuf -i 0-255 -n 1)); \/\//g"
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/pchMessageStart\[1\] =/pchMessageStart\[1\] = 0x$(printf "%x\n" $(shuf -i 0-255 -n 1)); \/\//g"
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/pchMessageStart\[2\] =/pchMessageStart\[2\] = 0x$(printf "%x\n" $(shuf -i 0-255 -n 1)); \/\//g"
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/pchMessageStart\[3\] =/pchMessageStart\[3\] = 0x$(printf "%x\n" $(shuf -i 0-255 -n 1)); \/\//g"

# Compile
cd $HOME/litecointemplate
make

# Mine mainnet genesis block
mkdir $HOME/mined_blocks
cd $HOME/litecointemplate/src
clear

cat <<EOF
--------
Mining mainnet genesis block.
Began mining $(date)

This could take up to four hours, perhaps even longer depending on your hardware.
--------
EOF

./litecoind > $HOME/mined_blocks/mainnet_info.txt
wait

# Update mainnet genesis block paramiters
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$MAINNET_MERKLE_ROOT/$(grep 'new mainnet genesis merkle root:' $HOME/mined_blocks/mainnet_info.txt | cut -f 2 -d ':' | xargs)/g"
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$MAINNET_NONCE/$(grep 'new mainnet genesis nonce:' $HOME/mined_blocks/mainnet_info.txt | cut -f 2 -d ':' | xargs)/g"
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$MAINNET_GENESIS_HASH/$(grep 'new mainnet genesis hash:' $HOME/mined_blocks/mainnet_info.txt | cut -f 2 -d ':' | xargs)/g"

# Initialize hashGenesisBlock value for mainnet
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "0,/hashGenesisBlock = uint256(\"0x01\")/{s/hashGenesisBlock = uint256(\"0x01\")/hashGenesisBlock = uint256(\"0x$(grep 'new mainnet genesis hash:' $HOME/mined_blocks/mainnet_info.txt | cut -f 2 -d ':' | xargs)\")/}"

# Switch off the mainnet genesis mining function
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "0,/if (true/{s/if (true/if (false/}"

# Compile again
cd $HOME/litecointemplate
make

# Mine testnet genesis block
cd $HOME/litecointemplate/src
clear

cat <<EOF
--------
Mining testnet genesis block.
Began mining $(date)

This could take up to four hours, perhaps even longer depending on your hardware.
--------
EOF

./litecoind > $HOME/mined_blocks/testnet_info.txt
wait

# Update testnet genesis block paramiters
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$TESTNET_NONCE/$(grep 'new testnet genesis nonce:' $HOME/mined_blocks/testnet_info.txt | cut -f 2 -d ':' | xargs)/g"
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$TESTNET_GENESIS_HASH/$(grep 'new testnet genesis hash:' $HOME/mined_blocks/testnet_info.txt | cut -f 2 -d ':' | xargs)/g"

# Initialize hashGenesisBlock value for testnet
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "0,/hashGenesisBlock = uint256(\"0x01\")/{s/hashGenesisBlock = uint256(\"0x01\")/hashGenesisBlock = uint256(\"0x$(grep 'new testnet genesis hash:' $HOME/mined_blocks/testnet_info.txt | cut -f 2 -d ':' | xargs)\")/}"

# Switch off the testnet genesis mining function
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "0,/if (true/{s/if (true/if (false/}"

# Compile for a third time
cd $HOME/litecointemplate
make

# Mine regtestnet genesis block
cd $HOME/litecointemplate/src
clear

cat <<EOF
--------
Mining regtestnet genesis block.
Began mining $(date)

This could take up to four hours, perhaps even longer depending on your hardware.
--------
EOF

./litecoind > $HOME/mined_blocks/regtestnet_info.txt
wait

# Update regtestnet genesis block paramiters
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/genesis.nNonce = 2/genesis.nNonce = $(grep 'new regtestnet genesis nonce:' $HOME/mined_blocks/regtestnet_info.txt | cut -f 2 -d ':' | xargs)/g"
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "s/$REGTESTNET_GENESIS_HASH/$(grep 'new regtestnet genesis hash:' $HOME/mined_blocks/regtestnet_info.txt | cut -f 2 -d ':' | xargs)/g"

# Initialize hashGenesisBlock value for regtestnet
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "0,/hashGenesisBlock = uint256(\"0x01\")/{s/hashGenesisBlock = uint256(\"0x01\")/hashGenesisBlock = uint256(\"0x$(grep 'new regtestnet genesis hash:' $HOME/mined_blocks/regtestnet_info.txt | cut -f 2 -d ':' | xargs)\")/}"

# Switch off the regtestnet genesis mining function
find $HOME/litecointemplate/src/ -name chainparams.cpp -print0 | xargs -0 sed -i \
    "0,/if (true/{s/if (true/if (false/}"

# Final compile
cd $HOME/litecointemplate
make

# Closing statement
clear
cat <<EOF
--------
Your new clone is ready to go.

Next steps,
Commit your new clone, be sure to save it as 'derrend/litecoinclone:node'.
In this example the container was named 'seed':

    docker commit seed derrend/litecoinclone:node && \
    docker rm seed

If you haven't already, clone the litecoinclone git repo:

    git clone https://github.com/derrend/litecoinclone.git

Move into 'litecoinclone/deployment_extention/', edit the 'litecoin.conf' file to your specifications and build any class of container you want (miner, non-miner).

    cd deployment_extention/

    #vi litecoin.conf
    docker build -t derrend/litecoinclone:miner .  # litecoin.conf, gen=1

    #vi litecoin.conf
    docker build -t derrend/litecoinclone:relay .  # litecoin.conf, gen=0

Run at least two instances to establish a network. You may deploy as many instances as you wish.

    docker run -d --name miner_1 derrend/litecoinclone:miner && \
    docker run -it --name relay_1 derrend/litecoinclone:relay

    #docker run -d --name class_n derrend/litecoinclone:class

Enjoy!
--------
EOF
