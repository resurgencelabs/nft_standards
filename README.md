# nft_standards
Experimental Private and Non Private NFT Standards for Aztec Network

# NOTE  
Currently this is an experimental repository. Code subject to change.  


# STEPS to Try  
aztec-cli create-account  
// note this $ADDRESS and $PRIVATEKEY  
cd pub721 (or pub721 or spn721)  
aztec-cli compile .  
aztec-cli deploy target/PUB721.json --args $ADDRESS  
// note the $CONTRACTADDRESS
// note: spn721 takes no argument for deploy  
aztec-cli send mint --args 0x01 0x02 0x30  --contract-artifact target/PUB721.json --contract-address $CONTRACTADDRESS --private-key $PRIVATEKEY  
// note: check out the spn721 code to see how many arguments are needed for mint. The code argument is a secret code that you must give the user whom you're transfering your private NFT to, for them to be able to  redeem it.  
aztec-cli create-account  
// note this $ADDRESS2  
aztec-cli send transfer --args 0x01 $ADDRESS2  --contract-artifact target/PUB721.json --contract-address $CONTRACTADDRESS --private-key $PRIVATEKEY  


