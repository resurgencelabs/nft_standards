mod address_note;
mod public_payload;

contract PN721 {
    use dep::std::option::Option;
    use dep::value_note::{
        balance_utils,
        utils::{increment, decrement},
        value_note::{VALUE_NOTE_LEN, ValueNote, ValueNoteMethods},
    };
    use dep::aztec::{
        context::{PrivateContext, PublicContext, Context},
        note::{
            note_header::NoteHeader,
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
        
    };
 
    use crate::address_note::{AddressNote, AddressNoteMethods, ADDRESS_NOTE_LEN};
    use crate::public_payload::{PublicPayload, PUBLIC_PAYLOAD_SERIALIZED_LEN, PublicPayloadSerializationMethods};
    
    struct Storage {
        // the attributes of the private NFT
        size: PublicState<Field, FIELD_SERIALIZED_LEN>,
        admin: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,
        owners: Map<Singleton<AddressNote, ADDRESS_NOTE_LEN>>,
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
                        Singleton::new(context, slot, AddressNoteMethods)
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

    #[aztec(public)]
    internal fn _add(proj: Field, tr: Field, now: Field, n: Field) {
        
        
        storage.size.write(n);

        let pub_payload = PublicPayload {
            project: proj,
            tier: tr,
            creation: now,
        };

        storage.nft_data.at(n).write(pub_payload);

    }

    // Mints nft with said specifications and assigns ownership to owner
    #[aztec(private)]
    fn mint( 
        proj: Field,
        tr: Field, 
        now: Field
    )  {
        
        let new_size = storage.size.read() + 1;
        let selector = compute_selector("_add((Field, Field, Field, Field))");
        context.call_public_function(context.this_address(), selector, [proj, tr, now, new_size]);
        
        let owner = context.msg_sender();
        let mut owner_note = AddressNote::new(owner);
        storage.owners.at(new_size).replace(&mut owner_note);

        
    }

    // Transfers nft with given `id` from msg_sender to  `recipient`.
    #[aztec(private)]
    fn transfer(
        id: Field, 
        recipient: Field,
    )  {
        
        
        let mut recipient_note = AddressNote::new(recipient);
        
        

        storage.owners.at(id).replace(&mut recipient_note);
    }


    unconstrained fn getData(
        id: Field,
    ) -> [Field; 3] {
        
        let pub_payload = storage.nft_data.at(id).read();
        
        let tier = pub_payload.tier;
        let creation = pub_payload.creation;
        let project = pub_payload.project;
        
        let res = [project, tier, creation];

        res
        
        
    }

    unconstrained fn getAdmin() -> Field {
        let admin = storage.admin.read();
        admin.address
    }

    unconstrained fn getSize() -> Field {
        let s = storage.size.read();
        s
    }


    // Computes note hash and nullifier.
    // Note 1: Needs to be defined by every contract producing logs.
    // Note 2: Having it in all the contracts gives us the ability to compute the note hash and nullifier differently for different kind of notes.
    unconstrained fn compute_note_hash_and_nullifier(contract_address: Field, nonce: Field, storage_slot: Field, preimage: [Field; VALUE_NOTE_LEN]) -> [Field; 4] {
        let note_header = NoteHeader::new(contract_address, nonce, storage_slot);
        note_utils::compute_note_hash_and_nullifier(ValueNoteMethods, note_header, preimage)
    }
}
