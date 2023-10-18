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
 
    use crate::address_note::{AddressNote, AddressNoteMethods, ADDRESS_NOTE_LEN};
    use crate::public_payload::{PublicPayload, PUBLIC_PAYLOAD_SERIALIZED_LEN, PublicPayloadSerializationMethods};
    
    struct Storage {
        // the attributes of the private NFT
        size: PublicState<Field, FIELD_SERIALIZED_LEN>,
        admin: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,
        owners: Map<Set<AddressNote, ADDRESS_NOTE_LEN>>,
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
                        Set::new(context, slot, AddressNoteMethods)
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
    fn mint(proj: Field, tr: Field, now: Field) -> Field{
        
        let new_size = storage.size.read() + 1;
        storage.size.write(new_size);

        let pub_payload = PublicPayload {
            project: proj,
            tier: tr,
            creation: now,
        };

        storage.nft_data.at(new_size).write(pub_payload);

        
        new_size
        

    }

    #[aztec(public)]
    internal fn _check_id_match(id: Field) {
        let size = storage.size.read();
        assert (size == id);
    }

    // The other half of the minting function, alongside mint() and it assigns ownership to the caller of the NFT 
    // whose id is provided as argument. The id fetched from the mint() function should be the id provided as argument
    #[aztec(private)]
    fn mint_private( 
        id: Field
    ) {
        let selector = compute_selector("_check_id_match(Field)");
        context.call_public_function(context.this_address(), selector, [id]);
        
        let owner = context.msg_sender();
        let mut owner_note = AddressNote::new(id, owner);

        let owner_set = storage.owners.at(owner);
        owner_set.insert(&mut owner_note);
        //storage.owners.at(new_size).replace(&mut owner_note);
        
        // Emit the newly created encrypted note preimages via oracle calls.
        let owner_key = get_public_key(owner);
        emit_encrypted_log(
            &mut context,
            context.this_address(),
            owner_set.storage_slot,
            owner_key,
            owner_note.serialize(),
        );
    }

    // Transfers nft with given `id` from msg_sender to  `recipient`. This doesn't alter the public_payload of the NFT
    #[aztec(private)]
    fn transfer(
        id: Field, 
        recipient: Field,
    )  {
        
        
        
        let owner = context.msg_sender();
        let options = NoteGetterOptions::new();
        let owner_notes = storage.owners.at(owner);
        let maybe_notes = owner_notes.get_notes(options);
        let mut flag = false;
        for i in 0..maybe_notes.len() {
            let j = i as u8;
            if (maybe_notes[i].is_some()) {
                let note = maybe_notes[i].unwrap_unchecked();
                if (id as u32 == note.address as u32) {
                    storage.owners.at(owner).remove(note);
                    flag = true;
                }
            }
        }
        if flag {
            let mut recipient_note = AddressNote::new(id, recipient);
            storage.owners.at(recipient).insert(&mut recipient_note);
            let recipient_notes = storage.owners.at(recipient);
            let new_owner_key = get_public_key(recipient);
            emit_encrypted_log(
                &mut context,
                context.this_address(),
                recipient_notes.storage_slot,
                new_owner_key,
                recipient_note.serialize(),
            );
        }
        
    }


    // Reads all notes under the given caller id Field, and asserts if the number of such notes is
    // at least n
    #[aztec(private)]
    fn read_all_notes(n: Field){
        let owner = context.msg_sender();
        let options = NoteGetterOptions::new();
        let owner_notes = storage.owners.at(owner);
        let maybe_notes = owner_notes.get_notes(options);
        //let selector = compute_selector("_check_id_match(Field)");
        //context.call_public_function(context.this_address(), selector, [maybe_notes.len()]);
        assert (maybe_notes[n - 1].is_some());

    }

    // checks if the user if a subscriber of the given tier for the given project, with the current timestamp
    // also being provided as an argument
    #[aztec(private)]
    fn is_subscriber(proj: Field, tier: Field, now: Field) {
        let owner = context.msg_sender();
        let options = NoteGetterOptions::new();
        let owner_notes = storage.owners.at(owner);
        let maybe_notes = owner_notes.get_notes(options);
        let mut assets_: [Field;13] = [0,0,0,0,0,0,0,0,0,0,0,0,0];
        for i in 0..maybe_notes.len() {
            let j = i as u8;
            if ((maybe_notes[i].is_some()) & (j < 10)) {
                let note = maybe_notes[i].unwrap_unchecked();
                assets_[i] = note.address;
            }
        }
        assets_[10] = proj;
        assets_[11] = tier;
        assets_[12] = now;
        let assets = assets_;
        let selector = compute_selector("_check_access([Field;13])");
        //let selector = compute_selector("_check_access([Field;10],Field,Field,Field)");
        context.call_public_function(context.this_address(), selector, assets);

    }

    // internal function that short circuits if user has no NFT to grant access for given project and tier
    #[aztec(public)]
    internal fn _check_access(assets: [Field;13]) {
        let mut flag = false;
        let mut tmax = 0 as u32;
        let proj = assets[10] as u32;
        let tier = assets[11] as u32;
        let now = assets[12] as u32;
        for i in 0..10{
            let asset = assets[i];
            if (asset != 0){
                let nft_data = storage.nft_data.at(asset).read();
                let t = nft_data.tier as u32;
                let p = nft_data.project as u32;
                let c = nft_data.creation as u32;
                if ((p == proj) & (now < (c + 30) )) {
                    flag = true;
                    if (t > tmax) {
                        tmax = t;
                    }
                }
            }
        }
        
       
        assert (tmax >= tier);
    }


    // gets all PUBLIC data for given NFT
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


    // Computes note hash and nullifier.
    // Note 1: Needs to be defined by every contract producing logs.
    // Note 2: Having it in all the contracts gives us the ability to compute the note hash and nullifier differently for different kind of notes.
    unconstrained fn compute_note_hash_and_nullifier(contract_address: Field, nonce: Field, storage_slot: Field, preimage: [Field; ADDRESS_NOTE_LEN]) -> [Field; 4] {
        let note_header = NoteHeader::new(contract_address, nonce, storage_slot);
        note_utils::compute_note_hash_and_nullifier(AddressNoteMethods, note_header, preimage)
    }
}