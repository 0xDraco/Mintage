module object_engine::schema {
    use std::string::String;

    public struct Schema has key, store{
        id: UID,
        fields: vector<String>
    }

    public fun new(fields: vector<String>, ctx: &mut TxContext): Schema {
        Schema { id: object::new(ctx), fields }
    }
}