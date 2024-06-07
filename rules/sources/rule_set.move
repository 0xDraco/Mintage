module rules::rule_set {
    use sui::dynamic_field as field;

    public struct RuleSet<phantom T> has key, store {
        id: UID,
        rules: vector<u64>
    }

    public struct RuleSetCap has key, store {
        id: UID,
        `for`: ID,
    }

    public struct Key has store, copy, drop {
        index: u64,
    }

    const ERuleAlreadyAdded: u64 = 0;

    public fun new<T>(ctx: &mut TxContext): (RuleSet<T>, RuleSetCap) {
        let rule_set = RuleSet { 
            id: object::new(ctx),
            rules: vector::empty() 
        };

        let rule_set_cap = RuleSetCap {
            id: object::new(ctx),
            `for`: rule_set.id.to_inner()
        };

        (rule_set, rule_set_cap)
    }

    public fun has<T>(self: &RuleSet<T>, id: u64): bool {
        self.rules.contains(&id)
    }

    public(package) fun add<T, Rule: store>(self: &mut RuleSet<T>, rule: Rule, id: u64) {
        assert!(self.has(id), ERuleAlreadyAdded);

        let key = Key { index: self.rules.length() };
        field::add(&mut self.id, key, rule);
        self.rules.push_back(id);
    }

    // public fun borrow<T: store>(self: &Rules, index: u64): &T {
    //     let key = Key { index };
    //     field::borrow(&self.id, key)
    // }

    // public fun borrow_mut<T: store>(self: &mut Rules, index: u64): &mut T {
    //     let key = Key { index };
    //     field::borrow_mut(&mut self.id, key)
    // }

    // public fun remove<T: store>(self: &mut Rules, index: u64): T {
    //     let key = Key { index };
    //     self.total_rules = self.total_rules - 1;
    //     field::remove(&mut self.id, key)
    // }

    public fun id<T>(self: &RuleSet<T>): ID {
        self.id.to_inner()
    }
}