mod address_note;

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
        state_vars::{map::Map, set::Set, public_state::PublicState, immutable_singleton::ImmutableSingleton},
        types::type_serialization::field_serialization::{
            FieldSerializationMethods, FIELD_SERIALIZED_LEN,
        },
    };

    use crate::address_note::{AddressNote, AddressNoteMethods, ADDRESS_NOTE_LEN};

    struct Storage {
        // the attributes of the private NFT
        size: PublicState<Field, FIELD_SERIALIZED_LEN>,
        admin: PublicState<Field, FIELD_SERIALIZED_LEN>,
        owners: Map<Set<AddressNote, ADDRESS_NOTE_LEN>>,
        projects: Map<PublicState<Field, FIELD_SERIALIZED_LEN>>,
        tiers: Map<PublicState<Field, FIELD_SERIALIZED_LEN>>,
        creation: Map<PublicState<Field, FIELD_SERIALIZED_LEN>>,
        beneficiaries: Map<PublicState<Field, FIELD_SERIALIZED_LEN>>,
        
    }

    impl Storage {
        fn init(context: Context) -> pub Self {
            Storage {
                size: PublicState::new(context, 1, FieldSerializationMethods),
                admin: PublicState::new(context, 2, FieldSerializationMethods),
                owners: Map::new(
                    context,
                    3, // Storage slot
                    |context, slot| {
                        Set::new(context, slot, AddressNoteMethods)
                    },
                ),
                projects: Map::new(
                    context,
                    4,
                    |context, slot| {
                        PublicState::new(context, slot, FieldSerializationMethods)
                    },
                ),
                tiers: Map::new(
                    context,
                    5,
                    |context, slot| {
                        PublicState::new(context, slot, FieldSerializationMethods)
                    },
                ),
                creation: Map::new(
                    context,
                    6,
                    |context, slot| {
                        PublicState::new(context, slot, FieldSerializationMethods)
                    },
                ),
                beneficiaries: Map::new(
                    context,
                    7,
                    |context, slot| {
                        PublicState::new(context, slot, FieldSerializationMethods)
                    },
                ),

                
               
            }
        }
    }

    // Constructs the contract and sets `size` of the collection to 0 at init
    #[aztec(private)]
    fn constructor( 
       admin_: Field 
    )  {
        
        storage.admin.write(admin_);
        //storage.admin.write(admin_);
        storage.size.write(0);
        
        
        
    }

    // Mints nft with said specifications and assigns ownership to owner
    #[aztec(private)]
    fn mint(
        project: Field,
        tier: Field, 
        now: Field
    )  {
        let owner = context.msg_sender();
        let new_size = storage.size.read() + 1;
        storage.projects.at(new_size).write(project);
        storage.owners.at(new_size).write(owner);
        storage.tiers.at(new_size).write(tier);
        storage.creation.at(new_size).write(now);
        
    }

    // Transfers nft with given `id` from msg_sender to  `recipient`.
    #[aztec(private)]
    fn transfer(
        id: Field, 
        recipient: Field,
    )  {
        
        let sender_ = context.msg_sender() as Field;
        let sender = AddressNote::new(sender_);
        let cur_owner = storage.owners.at(id);
        assert (cur_owner == sender);
        let mut note = AddressNote::new(id, recipient);
        

        storage.owners.write(id, recipient);
    }

    unconstrained fn getNFT(
        id: Field,
    ) -> [PublicState<Field, 1>] {
        
        
        let tier = storage.tiers.at(id);
        let creation = storage.creation.at(id);
        let project = storage.projects.at(id);
        
        let res = [tier, project, creation];

        res
        
    }

    // Computes note hash and nullifier.
    // Note 1: Needs to be defined by every contract producing logs.
    // Note 2: Having it in all the contracts gives us the ability to compute the note hash and nullifier differently for different kind of notes.
    unconstrained fn compute_note_hash_and_nullifier(contract_address: Field, nonce: Field, storage_slot: Field, preimage: [Field; VALUE_NOTE_LEN]) -> [Field; 4] {
        let note_header = NoteHeader::new(contract_address, nonce, storage_slot);
        note_utils::compute_note_hash_and_nullifier(ValueNoteMethods, note_header, preimage)
    }
}
