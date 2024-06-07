module object_engine::mint_policy {
    use sui::transfer_policy::{Self, TransferPolicy, TransferPolicyCap};
    use sui::balance::{Self, Balance};
    use sui::package::Publisher;
    use sui::coin::Coin;

    public struct MintPolicy<phantom T, phantom C> has key, store {
        id: UID,
        balance: Balance<C>,
        inner: TransferPolicy<T>
    }

    public fun new<T, C>(publisher: &Publisher, ctx: &mut TxContext): (MintPolicy<T, C>, TransferPolicyCap<T>) {
        let (policy, cap) = transfer_policy::new(publisher, ctx);
        let mint_policy = MintPolicy { id: object::new(ctx), inner: policy, balance: balance::zero() };

        (mint_policy, cap)
    }

    public fun add_to_balance<T, C, Rule: drop>(self: &mut MintPolicy<T, C>, _: Rule, coin: Coin<C>) {
        self.balance.join(coin.into_balance());
    }
}