module object_engine::object_engine {
    use std::string::String;

    use sui::package::Publisher;

    use object_engine::object_engine_inner::{Self, ObjectEngine, ObjectEngineOwnerCap};
    use object_engine::mint_policy::{MintPolicy, MintRequest};

    const EInvalidPublisher: u64 = 0;
    const EInvalidPolicyTag: u64 = 1;
    const EPolicyTagMismatch: u64 = 2;
    const EInvalidOwnerCap: u64 = 3;
    const ECannotLoadEmptyItems: u64 = 4;

     #[allow(lint(share_owned, self_transfer))]
    public fun default<T: key + store>(name: String, publisher: &Publisher, ctx: &mut TxContext) {
        let (object_engine, owner_cap) = new<T>(name, 0, true, publisher, ctx);

        transfer::public_share_object(object_engine);
        transfer::public_transfer(owner_cap, ctx.sender());
    }

    public fun new<T: key + store>(name: String, total_items: u64, is_random: bool, publisher: &Publisher, ctx: &mut TxContext): (ObjectEngine<T>, ObjectEngineOwnerCap) {
        assert!(publisher.from_package<T>(), EInvalidPublisher);

        let engine = object_engine_inner::new(name, total_items, is_random, ctx);
        let owner_cap = object_engine_inner::new_owner_cap(&engine, ctx);
        (engine, owner_cap)
    }

    public fun request_mint<T: key + store, C>(engine: &mut ObjectEngine<T>, policy: &MintPolicy<T, C>, _ctx: &mut TxContext): MintRequest<T> {
        let policies = engine.mint_policies();
        let policy_id = policies.try_get(policy.tag());

        assert!(policy_id.is_some(), EInvalidPolicyTag);
        assert!(policy_id.destroy_some() == policy.id(), EPolicyTagMismatch);

        let item = engine.pop_item();
        policy.new_request(item)
    }

    public fun complete_mint<T: key + store, C>(policy: &MintPolicy<T, C>, request: MintRequest<T>, _ctx: &mut TxContext): T {
        policy.confirm_request(request)
    }

    public fun load_items<T: key + store>(engine: &mut ObjectEngine<T>, owner_cap: &ObjectEngineOwnerCap, mut items: vector<T>) {
        assert!(engine.is_valid_owner_cap(owner_cap), EInvalidOwnerCap);
        assert!(!items.is_empty(), ECannotLoadEmptyItems);

        while(!items.is_empty()) {
            engine.add_item(items.pop_back())
        };
        items.destroy_empty()
    }

    public fun load_item<T: key + store>(engine: &mut ObjectEngine<T>, owner_cap: &ObjectEngineOwnerCap, item: T) {
        assert!(engine.is_valid_owner_cap(owner_cap), EInvalidOwnerCap);
        engine.add_item(item)
    }
}