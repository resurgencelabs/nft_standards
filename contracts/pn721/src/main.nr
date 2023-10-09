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
        state_vars::{map::Map, set::Set, public_state::PublicState},
    };
    use crate::address_note::{AddressNote, AddressNoteMethods, ADDRESS_NOTE_LEN};

    struct Storage {
        // the attributes of the private NFT
        size: PublicState<u16, 1>,
        admin: PublicState<Field, 1>,
        owners: Map<Set<AddressNote, ADDRESS_NOTE_LEN>>,
        projects: Map<PublicState<Field, Field>>,
        tiers: Map<PublicState<Field, u4>>,
        creation: Map<PublicState<Field, Field>>,
        beneficiaries: Map<PublicState<Field, Field>>,
    }

    impl Storage {
        fn init(context: Context) -> pub Self {
            Storage {
                size: 0,
                owners: Map::new(
                    context,
                    1, // Storage slot
                    |context, slot| {
                        Set::new(context, slot, AddressNoteMethods)
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
        storage.size.write(0);
        
        
    }

    // Mints nft with said specifications and assigns ownership to owner
    #[aztec(private)]
    fn mint(
        project: Field,
        tier: u4, 
        now: Field
    )  {
        let owner = context.msg_sender();
        let new_size = storage.size.read() + 1;
        storage.projects.write(new_size, project);
        storage.owners.write(new_size, owner);
        storage.tiers.write(new_size, tier);
        storage.creation.write(new_size, now);
        
    }

    // Transfers nft with given `id` from msg_sender to  `recipient`.
    #[aztec(private)]
    fn transfer(
        id: Field, 
        recipient: Field,
    )  {
        
        let sender = context.msg_sender();

        let cur_owner = storage.owners.at(id);
        assert (cur_owner == sender);

        storage.owners.write(id, recipient);
    }

    unconstrained fn getNFT(
        id: Field,
    ) -> [Field] {
        
        let owner = storage.owners.at(id);
        let tier = storage.tiers.at(id);
        let creation = storage.creation.at(id);
        let project = storage.projects.at(id);
        
        let res = [owner, tier as Field, project, creation];

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
