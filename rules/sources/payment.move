module rules::payment {
    public struct Payment<phantom T> {
        amount: u64,
        recipient: u64
    }

    public struct Rule has drop {}

    const EInvalidPaymentAmount: u64 = 0;

    public fun run<T>(self: &Payment<T>, coin: Coin<T>, ctx: &mut TxContext) {
        assert!(self.amount == coin::value(), EInvalidPaymentAmount);
        transfer::transfer(coin, self.recipient);
    
    }
}