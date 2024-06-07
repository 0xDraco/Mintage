module object_engine::object_engine {
    use std::string::String;

    use sui::transfer_policy::TransferRequest;
    use sui::dynamic_field as field;

    use object_engine::mint_policy::MintPolicy;

    use rules::rules::{Self, Rules};

    public struct Factory has key {
        id: UID,
        name: String,
        rules: Rules,
        total_items: u64,
        total_minted: u64,
        config: FactoryConfig
    }

    public struct FactoryConfig has store {
        is_random: bool,
        maximum_supply: u64
    }

    public struct FactoryOwnerCap has key, store {
        id: UID,
        `for`: ID
    }

    public struct Key has copy, store, drop {
        number: u64
    }

    const EMintAlreadyStarted: u64 = 0;
    const ECannotExceedMaximumSupply: u64 = 1;

    #[allow(lint(share_owned, self_transfer))]
    public fun default(name: String, ctx: &mut TxContext) {
        let (object_engine, owner_cap) = new(name, 0, true, ctx);

        transfer::share_object(object_engine);
        transfer::transfer(owner_cap, ctx.sender());
    }

    public fun new(name: String, total_items: u64, is_random: bool, ctx: &mut TxContext): (Factory, FactoryOwnerCap) {
        let rules = rules::new(ctx);
        let config = FactoryConfig { is_random, maximum_supply: 0 };
        let object_engine = Factory { id: object::new(ctx), name, rules, total_items, total_minted: 0, config };
        let owner_cap = new_object_engine_cap(&object_engine, ctx);

        (object_engine, owner_cap)
    }

    public fun load_items<T: key + store>(self: &mut Factory, mut items: vector<T>) {
        assert!(items.length() + self.total_items <= self.config.maximum_supply, ECannotExceedMaximumSupply);
        while(!items.is_empty()) {
            let item = items.pop_back();
            field::add(&mut self.id, Key { number: self.total_items }, item)
        };

        items.destroy_empty()
    }

    // #[allow(unused_variable)]
    // public fun mint_item<T, C>(self: &mut Factory, policy: MintPolicy<T, C>, request: TransferRequest<T>) {
        
    // }

    public fun set_random(self: &mut Factory, _owner_cap: &FactoryOwnerCap, is_random: bool) {
        assert!(self.total_minted == 0, EMintAlreadyStarted);
        self.config.is_random = is_random;
    }

    fun new_object_engine_cap(self: &Factory, ctx: &mut TxContext): FactoryOwnerCap {
        FactoryOwnerCap { id: object::new(ctx), `for`: object::id(self) }
    }
}
