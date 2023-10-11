   use dep::aztec::types::type_serialization::TypeSerializationInterface;
   
   struct PublicPayload {
        project: Field,
        tier: Field,
        creation: Field,
    }

    impl PublicPayload {

        pub fn new(project: Field,
        tier: Field,
        creation: Field,
         ) -> pub Self {
            Self {
                project,               
                tier,
                creation,
            }
        }
        pub fn get(&mut self,
         ) -> pub [Field] {
            [self.project, self.tier, self.creation]
        }
    }

global PUBLIC_PAYLOAD_SERIALIZED_LEN: Field = 3;

pub fn deserializePublicPayload(fields: [Field; PUBLIC_PAYLOAD_SERIALIZED_LEN]) -> pub PublicPayload {
    PublicPayload{project: fields[0] as Field, tier: fields[1] as Field, creation: fields[2] as Field}
}

pub fn serializePublicPayload(pp: PublicPayload) -> pub [Field; PUBLIC_PAYLOAD_SERIALIZED_LEN] {
    [pp.project, pp.tier, pp.creation]
}


global PublicPayloadSerializationMethods = TypeSerializationInterface {
    deserialize: deserializePublicPayload,
    serialize: serializePublicPayload,
};