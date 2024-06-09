module object::object {
    use std::string::String;

    use sui::vec_map::{Self, VecMap};

    public struct ObjectMetadata has key {
        id: UID,
        name: String,
        description: String,
        royalty_bps: Option<u16>,
        creator_shares: VecMap<address, u16>
    }

    public use fun to_vec_map as vector.to_vec_map;

    const BASIS_POINT_BASE: u16 = 10_000;

    const ECreatorsSharesLengthMismatch: u64 = 0;
    const EInvalidRoyaltyBpsValue: u64 = 1;

    public(package) fun new(name: String, description: String, royalty_bps: Option<u16>, mut creators: vector<address>, mut shares: vector<u16>) {
        if(royalty_bps.is_some()) {
            assert!(*royalty_bps.borrow() <= BASIS_POINT_BASE, EInvalidRoyaltyBpsValue);
        };

        let _shares = creators.to_vec_map(shares);

        // ObjectMetadata {}
    }

    fun to_vec_map<K: copy + store + drop, V: drop>(mut keys: vector<K>, mut values: vector<V>): VecMap<K, V> {
        assert!(keys.length() == values.length(), ECreatorsSharesLengthMismatch);
        let mut map = vec_map::empty();

        while(!keys.is_empty()) {
            map.insert(keys.pop_back(), values.pop_back())
        };

        map
    }
}