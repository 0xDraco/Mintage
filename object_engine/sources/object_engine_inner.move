module object_engine::object_engine_inner {
    use std::string::String;

    use sui::table::{Self, Table};
    use sui::vec_map::{Self, VecMap};

    /// An object structure representing the object engine. This stores the object engine's
    /// state and configuration.
    ///
    /// It takes a generic type `T` which is the type of the objects (NFTs) the engine is created for.
    public struct ObjectEngine<phantom T: key + store> has key, store {
        id: UID,
        /// The name of the object engine, this is used for nothing other than display.
        name: String,
        /// Indicates whether the object engine mints items randomly ot not.
        is_random: bool,
        /// This holds the total number of items in the engine.
        total_items: u64,
        /// The total number of items that have been minted from the object engine.
        total_minted: u64,
        /// The mint policies associated with the object engine. 
        /// This maps, the policies tag to their IDs.
        mint_policies: VecMap<String, ID>,
        /// This stores the items loaded into the object engine by the 
        items: Table<u64, T>
    }

    public struct ObjectEngineOwnerCap has key, store {
        id: UID,
        engine: ID
    }

    const EMintAlreadyStarted: u64 = 1;
    const ECannotExceedTotalItems: u64 = 2;
    const ECannotUseDuplicatePolicyTag: u64 = 3;
    const ENoItemInObjectEngine: u64 = 4;

    public(package) fun add_mint_policy<T: key + store>(self: &mut ObjectEngine<T>, tag: String, policy: ID) {
        let (tags, policies) = self.mint_policies.into_keys_values();
        assert!(!tags.contains(&tag), ECannotUseDuplicatePolicyTag);
        assert!(!policies.contains(&policy), ECannotUseDuplicatePolicyTag);

        self.mint_policies.insert(tag, policy)
    }

    public(package) fun remove_mint_policy<T: key + store>(self: &mut ObjectEngine<T>, tag: String) {
        assert!(self.mint_policies.contains(&tag), ECannotUseDuplicatePolicyTag);
        self.mint_policies.remove(&tag);
    }

    public(package) fun add_item<T: key + store>(self: &mut ObjectEngine<T>, item: T) {
        let total_items = self.items.length();

        assert!(total_items < self.total_items, ECannotExceedTotalItems);
        self.items.add(total_items, item);
    }

    public(package) fun pop_item<T: key + store>(self: &mut ObjectEngine<T>): T {
        let total_items = self.items.length();
        assert!(total_items > 0, ENoItemInObjectEngine);
        self.items.remove(total_items - 1)
    }

    public fun set_random<T: key + store>(self: &mut ObjectEngine<T>, _owner_cap: &ObjectEngineOwnerCap, is_random: bool) {
        assert!(self.total_minted == 0, EMintAlreadyStarted);
        self.is_random = is_random;
    }

    public fun is_valid_owner_cap<T: key + store>(self: &ObjectEngine<T>, cap: &ObjectEngineOwnerCap): bool {
        self.id.to_inner() == cap.engine
    }

    public fun mint_policies<T: key + store>(self: &ObjectEngine<T>): &VecMap<String, ID> {
        &self.mint_policies
    }

    public(package) fun new<T: key + store>(name: String, total_items: u64, is_random: bool, ctx: &mut TxContext): ObjectEngine<T> {
        let id = object::new(ctx);
        ObjectEngine { 
            id,
            name,
            is_random,
            total_items,
            total_minted: 0,
            items: table::new(ctx),
            mint_policies: vec_map::empty()
        }
    }

    public(package) fun new_owner_cap<T: key + store>(self: &ObjectEngine<T>, ctx: &mut TxContext): ObjectEngineOwnerCap {
        ObjectEngineOwnerCap { id: object::new(ctx), engine: object::id(self) }
    }
}
