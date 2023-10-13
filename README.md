# nft_standards
Experimental Private and Non Private NFT Standards for Aztec Network

# NOTE  
Currently this is an experimental repository. Forking not recommended unless for understanding purposes.


# STEPS to Try  
cd pn721  
aztec-cli create-account  
export ADDRESS=<address obtained in the previous step>
export PRIVATE=<private key obtained in the previous step>  
aztec-cli compile .   
aztec-cli deploy target/PN721.json -a $ADDRESS  
export CONTRACT=<contract address obtained in the previous step>  
aztec-cli call getData --args 0x07 --contract-artifact target/PN721.json --contract-address $CONTRACT 



