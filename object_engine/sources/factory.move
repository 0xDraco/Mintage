module object_engine::object_engine {
    use std::string::String;

    use sui::transfer_policy::TransferRequest;
    use sui::dynamic_field as field;

    use object_engine::mint_policy::MintPolicy;

    use rules::rule_set::{Self, RuleSet, RuleSetCap};

    public struct ObjectEngine<phantom T> has key {
        id: UID,
        name: String,
        total_items: u64,
        total_minted: u64,
        rule_set: Option<ID>,
        config: ObjectEngineConfig
    }

    public struct ObjectEngineConfig has store {
        is_random: bool,
        maximum_supply: u64
    }

    public struct ObjectEngineOwnerCap has key, store {
        id: UID,
        `for`: ID
    }

    public struct Key has copy, store, drop {
        number: u64
    }

    const EMintAlreadyStarted: u64 = 0;
    const ECannotExceedMaximumSupply: u64 = 1;

    #[allow(lint(share_owned, self_transfer))]
    public fun default<T>(name: String, ctx: &mut TxContext) {
        let (object_engine, owner_cap) = new<T>(name, 0, true, ctx);

        transfer::share_object(object_engine);
        transfer::transfer(owner_cap, ctx.sender());
    }

    public fun new<T>(name: String, total_items: u64, is_random: bool, ctx: &mut TxContext): (ObjectEngine<T>, ObjectEngineOwnerCap) {
        let config = new_config(is_random);
        let engine = new_internal(name, total_items, config, ctx);
        let owner_cap = new_owner_cap(&engine, ctx);

        (engine, owner_cap)
    }

    public fun add_rule_set<T>(self: &mut ObjectEngine<T>, _owner_cap: &ObjectEngineOwnerCap, ctx: &mut TxContext): (RuleSet<T>, RuleSetCap) {
        let (rule_set, rule_set_cap) = rule_set::new(ctx);
        self.rule_set.fill(rule_set.id());

        (rule_set, rule_set_cap)
    }

    public fun load_items<T: key + store>(self: &mut ObjectEngine<T>, mut items: vector<T>) {
        assert!(items.length() + self.total_items <= self.config.maximum_supply, ECannotExceedMaximumSupply);
        while(!items.is_empty()) {
            let item = items.pop_back();
            field::add(&mut self.id, Key { number: self.total_items }, item)
        };

        items.destroy_empty()
    }

    // #[allow(unused_variable)]
    // public fun mint_item<T, C>(self: &mut ObjectEngine, policy: MintPolicy<T, C>, request: TransferRequest<T>) {
        
    // }

    public fun set_random<T>(self: &mut ObjectEngine<T>, _owner_cap: &ObjectEngineOwnerCap, is_random: bool) {
        assert!(self.total_minted == 0, EMintAlreadyStarted);
        self.config.is_random = is_random;
    }

    public fun new_config(is_random: bool): ObjectEngineConfig {
        ObjectEngineConfig { is_random, maximum_supply: 0 }
    }

    // ===== Internal functions =====
    
    fun new_internal<T>(name: String, total_items: u64, config: ObjectEngineConfig,ctx: &mut TxContext): ObjectEngine<T> {
        let id = object::new(ctx);
        ObjectEngine { id, name, config, rule_set: option::none(), total_items, total_minted: 0 }
    }

    fun new_owner_cap<T>(self: &ObjectEngine<T>, ctx: &mut TxContext): ObjectEngineOwnerCap {
        ObjectEngineOwnerCap { id: object::new(ctx), `for`: object::id(self) }
    }
}
