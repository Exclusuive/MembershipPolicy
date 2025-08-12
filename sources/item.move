module exclusuive::item;

use exclusuive::community::{Community, get_uid, get_mut_uid, has_permission};
use exclusuive::membership::{
    Membership,
    get_membership_type,
    get_mut_uid_membership,
    get_uid_membership
};
use std::string::{Self, String};
use sui::dynamic_field;

public struct SlotType has copy, drop, store {
    community_id: ID,
    membership_type: String,
    slot_name: String,
}

public struct ItemType has copy, drop, store {
    community_id: ID,
    membership_type: String,
    slot_name: String,
    item_name: String,
    image_url: String,
}

public struct TraitType has copy, drop, store {
    community_id: ID,
    membership_type: String,
    trait_name: String,
}

public struct Item has key, store {
    id: UID,
    community_id: ID,
    membership_type: String,
    slot_name: String,
    item_name: String,
    image_url: String,
}

public struct Trait has store {
    community_id: ID,
    membership_type: String,
    trait_name: String,
    trait_value: u64,
}

public struct SlotTypeKey<phantom Type: store + copy + drop> has copy, drop, store {
    community_id: ID,
    membership_type: String,
    slot_name: String,
}

public struct ItemTypeKey<phantom Type: store + copy + drop> has copy, drop, store {
    community_id: ID,
    slot_name: String,
    membership_type: String,
    item_name: String,
}

public struct ItemKey<phantom Type: key + store> has copy, drop, store {
    community_id: ID,
    membership_type: String,
    slot_name: String,
}

public struct TraitTypeKey<phantom Type: store + copy + drop> has copy, drop, store {
    community_id: ID,
    membership_type: String,
    trait_name: String,
}

public fun new_slot_type(
    community: &mut Community,
    membership_type: String,
    slot_name: String,
    ctx: &mut TxContext,
) {
    let community_id = object::id(community);
    assert!(has_permission(community, string::utf8(b"item_manager"), ctx.sender()));
    assert!(
        !dynamic_field::exists_(
            get_uid(community),
            SlotTypeKey<SlotType> { community_id, membership_type, slot_name },
        ),
    );
    dynamic_field::add(
        get_mut_uid(community),
        SlotTypeKey<SlotType> { community_id, membership_type, slot_name },
        SlotType { community_id, membership_type, slot_name },
    );
    community.update_version();
}

public fun new_item_type(
    community: &mut Community,
    membership_type: String,
    slot_name: String,
    item_name: String,
    image_url: String,
    ctx: &mut TxContext,
) {
    let community_id = object::id(community);
    assert!(has_permission(community, string::utf8(b"item_manager"), ctx.sender()));
    assert!(
        dynamic_field::exists_(
            get_uid(community),
            SlotTypeKey<SlotType> { community_id, membership_type, slot_name },
        ),
    );
    assert!(
        !dynamic_field::exists_(
            get_uid(community),
            ItemTypeKey<ItemType> { community_id, membership_type, slot_name, item_name },
        ),
    );
    dynamic_field::add(
        get_mut_uid(community),
        ItemTypeKey<ItemType> { community_id, membership_type, slot_name, item_name },
        ItemType { community_id, membership_type, slot_name, item_name, image_url },
    );
}

public fun new_trait_type(
    community: &mut Community,
    membership_type: String,
    trait_name: String,
    ctx: &mut TxContext,
) {
    let community_id = object::id(community);
    assert!(has_permission(community, string::utf8(b"item_manager"), ctx.sender()));
    assert!(
        !dynamic_field::exists_(
            get_uid(community),
            TraitTypeKey<TraitType> { community_id, membership_type, trait_name },
        ),
    );
    dynamic_field::add(
        get_mut_uid(community),
        TraitTypeKey<TraitType> { community_id, membership_type, trait_name },
        TraitType { community_id, membership_type, trait_name },
    );
    community.update_version();
}

public fun new_item(
    community: &mut Community,
    membership_type: String,
    slot_name: String,
    item_name: String,
    ctx: &mut TxContext,
): Item {
    let community_id = object::id(community);
    assert!(has_permission(community, string::utf8(b"item_manager"), ctx.sender()));
    let item_type: &mut ItemType = dynamic_field::borrow_mut(
        get_mut_uid(community),
        ItemTypeKey<ItemType> { community_id, membership_type, slot_name, item_name },
    );
    let item_id = object::new(ctx);
    Item {
        id: item_id,
        community_id,
        membership_type,
        slot_name,
        item_name,
        image_url: item_type.image_url,
    }
}

public fun new_trait(
    community: &mut Community,
    membership_type: String,
    trait_name: String,
    trait_value: u64,
    ctx: &mut TxContext,
): Trait {
    let community_id = object::id(community);
    assert!(has_permission(community, string::utf8(b"item_manager"), ctx.sender()));
    assert!(
        dynamic_field::exists_(
            get_uid(community),
            TraitTypeKey<TraitType> { community_id, membership_type, trait_name },
        ),
    );
    Trait {
        community_id,
        membership_type,
        trait_name,
        trait_value,
    }
}

public fun attach_trait_to_item(community: &mut Community, item: &mut Item, trait: Trait) {
    dynamic_field::add(
        &mut item.id,
        TraitTypeKey<TraitType> {
            community_id: object::id(community),
            membership_type: item.membership_type,
            trait_name: trait.trait_name,
        },
        trait,
    )
}

#[allow(lint(self_transfer))]
public fun equip_item_to_membership(
    community: &mut Community,
    membership: &mut Membership,
    item: Item,
    ctx: &mut TxContext,
) {
    let mt = get_membership_type(membership);

    if (
        !dynamic_field::exists_<ItemKey<Item>>(
            get_uid_membership(membership),
            ItemKey<Item> {
                community_id: object::id(community),
                membership_type: mt,
                slot_name: item.slot_name,
            },
        )
    ) {
        dynamic_field::add(
            get_mut_uid_membership(membership),
            ItemKey<Item> {
                community_id: object::id(community),
                membership_type: mt,
                slot_name: item.slot_name,
            },
            item,
        );
    } else {
        let old_item: Item = dynamic_field::remove(
            get_mut_uid_membership(membership),
            ItemKey<Item> {
                community_id: object::id(community),
                membership_type: mt,
                slot_name: item.slot_name,
            },
        );

        dynamic_field::add(
            get_mut_uid_membership(membership),
            ItemKey<Item> {
                community_id: object::id(community),
                membership_type: mt,
                slot_name: item.slot_name,
            },
            item,
        );
        transfer::public_transfer(old_item, ctx.sender());
    };
}

#[allow(lint(self_transfer))]
public fun unequip_item_from_membership(
    community: &mut Community,
    membership: &mut Membership,
    slot_name: String,
    ctx: &mut TxContext,
) {
    let mt = get_membership_type(membership);
    assert!(
        dynamic_field::exists_(
            get_mut_uid_membership(membership),
            ItemKey<Item> {
                community_id: object::id(community),
                membership_type: mt,
                slot_name,
            },
        ),
    );
    let item: Item = dynamic_field::remove(
        get_mut_uid_membership(membership),
        ItemKey<Item> {
            community_id: object::id(community),
            membership_type: mt,
            slot_name: slot_name,
        },
    );
    transfer::public_transfer(item, ctx.sender());
}
