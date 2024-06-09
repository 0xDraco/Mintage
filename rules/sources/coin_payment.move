module rules::coin_payment {
    use sui::coin::Coin;
    use sui::transfer_policy::{Self, TransferPolicy, TransferPolicyCap, TransferRequest};

    public struct CoinPayment<phantom T> has store, drop {
        amount: u64,
        recipient: address
    }

    public struct Rule has drop {}

    const EInvalidPaymentAmount: u64 = 0;

    public fun add<T, C>(policy: &mut TransferPolicy<T>, cap: &TransferPolicyCap<T>, amount: u64, recipient: address) {
        let payment = CoinPayment<C> { amount, recipient };
        transfer_policy::add_rule(Rule {}, policy, cap, payment)
    }

    public fun remove<T, C>(policy: &mut TransferPolicy<T>, cap: &TransferPolicyCap<T>) {
        transfer_policy::remove_rule<T, Rule, CoinPayment<C>>(policy, cap);
    }

    public fun apply<T, C>(policy: &TransferPolicy<T>, request: &mut TransferRequest<T>, coin: Coin<C>) {
        let payment: &CoinPayment<C> = transfer_policy::get_rule(Rule {}, policy);
        assert!(payment.amount == coin.value(), EInvalidPaymentAmount);

        transfer::public_transfer(coin, payment.recipient);
        transfer_policy::add_receipt(Rule {}, request)
    }
}