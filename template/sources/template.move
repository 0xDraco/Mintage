module template::template {
    use std::string::{utf8, String};

    use sui::display;
    use sui::vec_map::{Self, VecMap};
    use sui::package::{Self, Publisher};

    use object_engine::object_engine::{Self, ObjectEngine, ObjectEngineOwnerCap};

    public struct Template has key, store {
        id: UID,
        name: String,
        attributes: VecMap<String, String>
    }

    public struct TEMPLATE has drop {}

    const EInvalidPackagePublisher: u64 = 0;
    const EEngineOwnerCapMismatch: u64 = 1;

    fun init(template: TEMPLATE, ctx: &mut TxContext) {
        let publisher = package::claim(template, ctx);
        transfer::public_transfer(publisher, ctx.sender())
    }

    public fun setup_display(engine: &ObjectEngine<Template>, cap: &ObjectEngineOwnerCap, publisher: &Publisher, ctx: &mut TxContext) {
        assert!(engine.is_valid_owner_cap(cap), EEngineOwnerCapMismatch);

        let mut display = display::new<Template>(publisher, ctx);
        display.add(utf8(b"name"), utf8(b""));
        display.update_version();

        transfer::public_transfer(display, ctx.sender())
    }

    // public fun create(engine: &ObjectEngine<Template>, cap: &ObjectEngineOwnerCap, ctx: &mut TxContext): Template {
    //     assert!(engine.is_valid_owner_cap(cap), EEngineOwnerCapMismatch);
    //     Template { id: object::new(ctx), attributes: vec_map::empty() }
    // }
}