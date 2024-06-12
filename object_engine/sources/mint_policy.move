module object_engine::mint_policy {
    use std::type_name;
    use std::string::String;

    use sui::transfer_policy::{Self, TransferPolicy, TransferPolicyCap, TransferRequest};
    use sui::package::Publisher;
    use sui::bag::{Self, Bag};
    use sui::balance::Balance;
    use sui::coin::Coin;

    public struct MintPolicy<phantom T> has key, store {
        id: UID,
        tag: String,
        balances: Bag,
        inner: TransferPolicy<T>
    }

    public struct MintRequest<T: key + store> {
        item: T,
        policy: ID,
        inner: TransferRequest<T>
    }

    public struct MintPolicyCap<phantom T> has key, store {
        id: UID,
        inner: TransferPolicyCap<T>
    }

    const EPolicyIdMismatch: u64 = 0;

    public fun new<T>(tag: String, publisher: &Publisher, ctx: &mut TxContext): (MintPolicy<T>, TransferPolicyCap<T>) {
        let (inner, cap) = transfer_policy::new(publisher, ctx);
        let mint_policy = MintPolicy { 
            id: object::new(ctx), 
            tag,
            inner,
            balances: bag::new(ctx) 
        };

        (mint_policy, cap)
    }

    public(package) fun new_request<T: key + store>(policy: &MintPolicy<T>, item: T): MintRequest<T> {
       let inner = transfer_policy::new_request<T>(object::id(&item), 0, policy.id());
       MintRequest { item, inner, policy: policy.id() }
    }

    public(package) fun confirm_request<T: key + store>(policy: &MintPolicy<T>, request: MintRequest<T>): T {
        let MintRequest<T> { item, inner, policy: policy_id } = request;
        
        assert!(policy.id() == policy_id, EPolicyIdMismatch);
        let (item_id, _, _from) = transfer_policy::confirm_request(&policy.inner, inner);
        assert!(item_id == object::id(&item), EPolicyIdMismatch);

        item
    }

    public fun add_to_balance<T, C, Rule: drop>(self: &mut MintPolicy<T>, _: Rule, coin: Coin<C>) {
        let coin_type = type_name::get<C>().into_string();
        if(self.balances.contains_with_type<std::ascii::String, Balance<C>>(coin_type)) {
            let balance = self.balances.borrow_mut<std::ascii::String, Balance<C>>(coin_type);
            balance.join(coin.into_balance());
        } else {
            self.balances.add(coin_type, coin.into_balance())
        }
    }

    public fun id<T>(self: &MintPolicy<T>): ID {
        self.id.to_inner()
    }

    public fun tag<T>(self: &MintPolicy<T>): &String {
        &self.tag
    }
}