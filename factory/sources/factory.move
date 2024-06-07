module factory::factory {
    use std::string::String;

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
    }

    public struct FactoryOwnerCap has key, store {
        id: UID,
        `for`: ID
    }

    const EMintAlreadyStarted: u64 = 0;

    #[allow(lint(share_owned, self_transfer))]
    public fun default(name: String, ctx: &mut TxContext) {
        let (factory, owner_cap) = new(name, 0, true, ctx);

        transfer::share_object(factory);
        transfer::transfer(owner_cap, ctx.sender());
    }

    public fun new(name: String, total_items: u64, is_random: bool, ctx: &mut TxContext): (Factory, FactoryOwnerCap) {
        let rules = rules::new(ctx);
        let config = FactoryConfig {is_random};
        let factory = Factory { id: object::new(ctx), name, rules, total_items, total_minted: 0, config };
        let owner_cap = new_factory_cap(&factory, ctx);

        (factory, owner_cap)
    }

    public fun set_random(self: &mut Factory, _owner_cap: &FactoryOwnerCap, is_random: bool) {
        assert!(self.total_minted == 0, EMintAlreadyStarted);
        self.config.is_random = is_random;
    }

    fun new_factory_cap(self: &Factory, ctx: &mut TxContext): FactoryOwnerCap {
        FactoryOwnerCap { id: object::new(ctx), `for`: object::id(self) }
    }
}
