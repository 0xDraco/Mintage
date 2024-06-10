module object_engine::mint_policy {
    use std::string::String;

    use sui::transfer_policy::{Self, TransferPolicy, TransferPolicyCap, TransferRequest};
    use sui::balance::{Self, Balance};
    use sui::package::Publisher;
    use sui::coin::Coin;

    public struct MintPolicy<phantom T, phantom C> has key, store {
        id: UID,
        tag: String,
        balance: Balance<C>,
        inner: TransferPolicy<T>
    }

    public struct MintRequest<T: key + store> {
        item: T,
        policy: ID,
        inner: TransferRequest<T>
    }

    const EPolicyIdMismatch: u64 = 0;

    public fun new<T, C>(tag: String, publisher: &Publisher, ctx: &mut TxContext): (MintPolicy<T, C>, TransferPolicyCap<T>) {
        let (policy, cap) = transfer_policy::new(publisher, ctx);
        let mint_policy = MintPolicy { id: object::new(ctx), tag, inner: policy, balance: balance::zero() };

        (mint_policy, cap)
    }

    public(package) fun new_request<T: key + store, C>(policy: &MintPolicy<T, C>, item: T): MintRequest<T> {
       let inner = transfer_policy::new_request<T>(object::id(&item), 0, policy.id());
       MintRequest { item, inner, policy: policy.id() }
    }

    public(package) fun confirm_request<T: key + store, C>(policy: &MintPolicy<T, C>, request: MintRequest<T>): T {
        let MintRequest<T> { item, inner, policy: policy_id } = request;
        
        assert!(policy.id() == policy_id, EPolicyIdMismatch);
        let (item_id, _, _from) = transfer_policy::confirm_request(&policy.inner, inner);
        assert!(item_id == object::id(&item), EPolicyIdMismatch);

        item
    }

    public fun add_to_balance<T, C, Rule: drop>(self: &mut MintPolicy<T, C>, _: Rule, coin: Coin<C>) {
        self.balance.join(coin.into_balance());
    }

    public fun id<T, C>(self: &MintPolicy<T, C>): ID {
        self.id.to_inner()
    }

    public fun tag<T, C>(self: &MintPolicy<T, C>): &String {
        &self.tag
    }

    public fun balance<T, C>(self: &MintPolicy<T, C>): u64 {
        self.balance.value()
    }
}