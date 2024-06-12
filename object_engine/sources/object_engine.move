module object_engine::object_engine {
    use std::string::String;

    use sui::package::Publisher;
    use sui::table::{Self, Table};
    use sui::transfer_policy::TransferPolicy;
    use sui::kiosk::{Kiosk, KioskOwnerCap};
    use sui::vec_map::{Self, VecMap};

    use object_engine::mint_policy::{MintPolicy, MintRequest};

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
        /// This stores the items loaded into the object engine by the 
        items: Table<u64, T>,
        /// The mint policies associated with the object engine. 
        /// This maps, the policies tag to their IDs.
        mint_policies: VecMap<String, ID>
    }

    public struct ObjectEngineOwnerCap has key, store {
        id: UID,
        engine: ID
    }

    const EMintAlreadyStarted: u64 = 1;
    const ECannotExceedTotalItems: u64 = 2;
    const ECannotUseDuplicatePolicyTag: u64 = 3;
    const ENoItemInObjectEngine: u64 = 4;
    const EInvalidPublisher: u64 = 0;
    const EInvalidPolicyTag: u64 = 1;
    const EPolicyTagMismatch: u64 = 2;
    const EInvalidOwnerCap: u64 = 3;
    const ECannotLoadEmptyItems: u64 = 4;

    #[allow(lint(share_owned, self_transfer))]
    public fun default<T: key + store>(name: String, total_items: u64, is_random: bool, publisher: &Publisher, ctx: &mut TxContext) {
        let (object_engine, owner_cap) = new<T>(name, total_items, is_random, publisher, ctx);

        transfer::public_share_object(object_engine);
        transfer::public_transfer(owner_cap, ctx.sender());
    }

    public fun new<T: key + store>(name: String, total_items: u64, is_random: bool, publisher: &Publisher, ctx: &mut TxContext): (ObjectEngine<T>, ObjectEngineOwnerCap) {
        assert!(publisher.from_package<T>(), EInvalidPublisher);

        let engine = new_internal(name, total_items, is_random, ctx);
        let owner_cap = engine.new_owner_cap(ctx);
        (engine, owner_cap)
    }

    public fun request_mint<T: key + store>(self: &mut ObjectEngine<T>, policy: &MintPolicy<T>, _ctx: &mut TxContext): MintRequest<T> {
        let policies = self.mint_policies();
        let policy_id = policies.try_get(policy.tag());

        assert!(policy_id.is_some(), EInvalidPolicyTag);
        assert!(policy_id.destroy_some() == policy.id(), EPolicyTagMismatch);

        let item = self.pop_item();
        policy.new_request(item)
    }

    public fun complete_mint<T: key + store>(policy: &MintPolicy<T>,kiosk: &mut Kiosk, kiosk_cap: &KioskOwnerCap, tf_policy: &TransferPolicy<T>, request: MintRequest<T>) {
        let item = policy.confirm_request(request);
        kiosk.lock(kiosk_cap, tf_policy, item)
    }

    public fun add_items<T: key + store>(self: &mut ObjectEngine<T>, owner_cap: &ObjectEngineOwnerCap, mut items: vector<T>) {
        assert!(self.is_valid_owner_cap(owner_cap), EInvalidOwnerCap);
        assert!(!items.is_empty(), ECannotLoadEmptyItems);

        while(!items.is_empty()) {
            self.add_item_internal(items.pop_back())
        };
        items.destroy_empty()
    }

    public fun add_item<T: key + store>(self: &mut ObjectEngine<T>, owner_cap: &ObjectEngineOwnerCap, item: T) {
        assert!(self.is_valid_owner_cap(owner_cap), EInvalidOwnerCap);
        self.add_item_internal(item)
    }

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

    public(package) fun add_item_internal<T: key + store>(self: &mut ObjectEngine<T>, item: T) {
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

    public(package) fun new_internal<T: key + store>(name: String, total_items: u64, is_random: bool, ctx: &mut TxContext): ObjectEngine<T> {
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
