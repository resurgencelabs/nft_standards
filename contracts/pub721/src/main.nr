mod public_payload;

contract PUB721 {
    use dep::std::option::Option; 
    use dep::aztec::{
        context::{PrivateContext, PublicContext, Context},
        note::{
            note_header::NoteHeader,
            note_getter_options::NoteGetterOptions,
            utils as note_utils,
        },
        state_vars::{map::Map, set::Set, public_state::PublicState, singleton::Singleton},
        types::type_serialization::{
            field_serialization::{FieldSerializationMethods, FIELD_SERIALIZED_LEN},
            bool_serialization::{BoolSerializationMethods, BOOL_SERIALIZED_LEN},
            aztec_address_serialization::{AztecAddressSerializationMethods, AZTEC_ADDRESS_SERIALIZED_LEN},
        },
        types::address::{AztecAddress},
        selector::compute_selector,
        log::emit_encrypted_log,
        oracle::get_public_key::get_public_key,
    };
 
    use crate::public_payload::{PublicPayload, PUBLIC_PAYLOAD_SERIALIZED_LEN, PublicPayloadSerializationMethods};
    
    struct Storage {
        // the attributes of the private NFT
        size: PublicState<Field, FIELD_SERIALIZED_LEN>,
        admin: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,
        owners: Map<PublicState<Field, FIELD_SERIALIZED_LEN>>,
        nft_data: Map<PublicState<PublicPayload, PUBLIC_PAYLOAD_SERIALIZED_LEN>>,
        
        
    }

    impl Storage {
        fn init(context: Context) -> pub Self {
            Storage {
                size: PublicState::new(context, 1, FieldSerializationMethods),
                admin: PublicState::new(context, 2, AztecAddressSerializationMethods),
                owners: Map::new(
                    context,
                    3, // Storage slot
                    |context, slot| {
                        PublicState::new(context, slot, FieldSerializationMethods)
                    },
                ),
                nft_data: Map::new(
                    context,
                    4,
                    |context, slot| {
                        PublicState::new(context, slot, PublicPayloadSerializationMethods)
                    },
                ),

                
               
            }
        }
    }

    // Constructs the contract and sets `size` of the collection to 0 at init
    #[aztec(private)]
    fn constructor( 
       admin_: AztecAddress 
    )  {
        let selector = compute_selector("_init((Field))");
        context.call_public_function(context.this_address(), selector, [admin_.address]);
       
             
        
        
    }

    #[aztec(public)]
    internal fn _init(admin_: AztecAddress) {
        storage.admin.write(admin_);
        storage.size.write(0);
    }

   
    // The public mint function, to mint a new NFT, to be used in tandem with mint_private function
    #[aztec(public)]
    fn mint(proj: Field, tr: Field, ex: Field) -> Field{
        
        let new_size = storage.size.read() + 1;
        storage.size.write(new_size);

        let pub_payload = PublicPayload {
            project: proj,
            tier: tr,
            expiry: ex,
        };

        storage.nft_data.at(new_size).write(pub_payload);

        let owner = context.msg_sender();

        storage.owners.at(new_size).write(owner);

        
        new_size
        

    }

    

    

    // Transfers nft with given `id` from msg_sender to  `recipient`. This doesn't alter the public_payload of the NFT
    #[aztec(public)]
    fn transfer(
        id: Field, 
        recipient: Field,
    )  {
        
        let nft_owner = storage.owners.at(id).read();
        let caller = context.msg_sender();
        assert (nft_owner == caller);

        storage.owners.at(id).write(recipient);
        
        
        
    }


    
    
    unconstrained fn is_subscriber(proj: Field, tier: Field, now: Field, account: Field) -> Field {
        let size = storage.size.read();
        let mut ex = 0 as u32;
        let mut pr = 0 as u32;
        let mut tr = 0 as u32;
        let mut tmax = 0 as u32;
        let mut owner = 0  as Field;
        for i in 1..(size+1) {
            
            owner = storage.owners.at(i).read();
            if (owner == account) {
                let pub_payload = storage.nft_data.at(i).read();
                pr = pub_payload.project as u32;
                tr = pub_payload.tier as u32;
                ex = pub_payload.expiry as u32;
                if ((pr == proj  as u32) & (now as u32 < ex)){
                    if tr > tmax {
                        tmax = tr;
                    }
                }
            }
            
            
        }
        assert (tmax >= tier as u32);
        1
    }

    


    // gets all PUBLIC data for given NFT
    unconstrained fn getData(
        id: Field,
    ) -> [Field; 3] {
        
        let pub_payload = storage.nft_data.at(id).read();
        
        let tier = pub_payload.tier;
        let expiry = pub_payload.expiry;
        let project = pub_payload.project;
        
        let res = [project, tier, expiry];

        res
        
        
    }

    // gets the admin for the said contract
    unconstrained fn getAdmin() -> Field {
        let admin = storage.admin.read();
        admin.address
    }

    // outputs the size of the NFT collection
    unconstrained fn getSize() -> Field {
        let s = storage.size.read();
        s
    }


    
}