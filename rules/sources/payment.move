module rules::payment {
    use sui::coin::Coin;

    public struct Payment<phantom T> has store {
        amount: u64,
        recipient: address
    }

    public struct Rule has drop {}

    const EInvalidPaymentAmount: u64 = 0;

    public fun new<T>(amount: u64, recipient: address): Payment<T> {
        Payment { amount, recipient }
    }

    public fun run<T>(self: &Payment<T>, coin: Coin<T>) {
        assert!(self.amount == coin.value(), EInvalidPaymentAmount);
        transfer::public_transfer(coin, self.recipient);
    }
}