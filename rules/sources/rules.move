module rules::rules {
    use sui::dynamic_field as field;

    public struct Rules has key, store {
        id: UID,
        total_rules: u64,
    }

    public struct Key has store, copy, drop {
        index: u64,
    }

    public fun new(ctx: &mut TxContext): Rules {
        let id = object::new(ctx);
        Rules { id, total_rules: 0 }
    }

    public fun add<T: store>(self: &mut Rules, rule: T) {
        let key = Key { index: self.total_rules };
        self.total_rules = self.total_rules + 1;

        field::add(&mut self.id, key, rule);
    }

    public fun borrow<T: store>(self: &Rules, index: u64): &T {
        let key = Key { index };
        field::borrow(&self.id, key)
    }

    public fun borrow_mut<T: store>(self: &mut Rules, index: u64): &mut T {
        let key = Key { index };
        field::borrow_mut(&mut self.id, key)
    }

    public fun remove<T: store>(self: &mut Rules, index: u64): T {
        let key = Key { index };
        self.total_rules = self.total_rules - 1;
        field::remove(&mut self.id, key)
    }
}