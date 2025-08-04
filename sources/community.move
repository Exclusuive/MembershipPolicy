module exclusuive::community;

use std::string::String;
use sui::balance::{Self, Balance};
use sui::dynamic_field;
use sui::sui::SUI;

public struct Community has key, store {
    id: UID,
    balance: Balance<SUI>,
    version: u64,
}

// =======================================================
// ======================== Types
// =======================================================

public struct MembershipType has copy, drop, store {
    community_id: ID,
    type_name: String,
}

public struct PartType has copy, drop, store {
    community_id: ID,
    membership_type: String,
    type_name: String,
}

public struct ItemType has copy, drop, store {
    community_id: ID,
    membership_type: String,
    part_type: String,
    type_name: String,
    image_url: String,
}

public struct AttributeType has copy, drop, store {
    community_id: ID,
    type_name: String,
}

public struct TicketType has copy, drop, store {
    community_id: ID,
    type_name: String,
}

// =======================================================
// ======================== Keys
// =======================================================

public struct TypeKey<phantom Type: store + copy + drop> has copy, drop, store {
    type_name: String,
}

public struct ConfigType has copy, drop, store {
    content: String,
}

// =======================================================
// ======================== Objects
// =======================================================

public struct Item has key, store {
    id: UID,
    `type`: ItemType,
}

public struct Attribute has store {
    `type`: AttributeType,
    value: u64,
}

public struct Ticket has key, store {
    id: UID,
    `type`: TicketType,
}

// =======================================================
// ======================== Register Type Functions
// =======================================================

public fun new_community(ctx: &mut TxContext): Community {
    let community = Community {
        id: object::new(ctx),
        balance: balance::zero(),
        version: 0,
    };
    community
}

public fun register_membership_type(community: &mut Community, type_name: String) {
    let community_id = object::id(community);
    let membership_type = MembershipType {
        community_id,
        type_name,
    };

    dynamic_field::add(
        &mut community.id,
        TypeKey<MembershipType> { type_name },
        membership_type,
    );

    community.update_version();
}

public fun register_part_type(
    community: &mut Community,
    membership_type: String,
    type_name: String,
) {
    let community_id = object::id(community);
    assert!(
        dynamic_field::exists_(
            &community.id,
            TypeKey<MembershipType> { type_name: membership_type },
        ),
    );
    dynamic_field::add(
        &mut community.id,
        TypeKey<PartType> { type_name },
        PartType { community_id, membership_type, type_name },
    );
}

public fun register_item_type(
    community: &mut Community,
    membership_type: String,
    part_type: String,
    type_name: String,
    image_url: String,
) {
    let community_id = object::id(community);
    assert!(
        dynamic_field::exists_(
            &community.id,
            TypeKey<MembershipType> { type_name: membership_type },
        ),
    );
    assert!(
        dynamic_field::exists_(
            &community.id,
            TypeKey<PartType> { type_name: part_type },
        ),
    );
    dynamic_field::add(
        &mut community.id,
        TypeKey<ItemType> { type_name },
        ItemType { community_id, membership_type, part_type, type_name, image_url },
    );
}

public fun register_attribute_type(community: &mut Community, type_name: String) {
    let community_id = object::id(community);
    dynamic_field::add(
        &mut community.id,
        TypeKey<AttributeType> { type_name },
        AttributeType { community_id, type_name },
    );
    community.update_version();
}

public fun register_ticket_type(community: &mut Community, type_name: String) {
    let community_id = object::id(community);
    dynamic_field::add(
        &mut community.id,
        TypeKey<TicketType> { type_name },
        TicketType { community_id, type_name },
    );
    community.update_version();
}

// =======================================================
// ======================== Additional Information Functions
// =======================================================

public fun register_config_type(community: &mut Community, type_name: String, content: String) {
    dynamic_field::add(
        &mut community.id,
        TypeKey<ConfigType> { type_name },
        ConfigType { content },
    );
    community.update_version();
}

public fun update_config_type(community: &mut Community, type_name: String, content: String) {
    assert!(dynamic_field::exists_(&community.id, TypeKey<ConfigType> { type_name }));
    let config = dynamic_field::borrow_mut<TypeKey<ConfigType>, ConfigType>(
        &mut community.id,
        TypeKey<ConfigType> { type_name },
    );
    config.content = content;
}

// =======================================================
// ========================  Object Functions
// =======================================================

public fun new_item(community: &mut Community, type_name: String, ctx: &mut TxContext): Item {
    let id = object::new(ctx);
    assert!(dynamic_field::exists_(&community.id, TypeKey<ItemType> { type_name }));
    let item_type = dynamic_field::borrow<TypeKey<ItemType>, ItemType>(
        &community.id,
        TypeKey<ItemType> { type_name },
    );
    Item { id, `type`: *item_type }
}

public fun new_ticket(community: &mut Community, type_name: String, ctx: &mut TxContext): Ticket {
    let id = object::new(ctx);
    assert!(dynamic_field::exists_(&community.id, TypeKey<TicketType> { type_name }));
    let ticket_type = dynamic_field::borrow<TypeKey<TicketType>, TicketType>(
        &community.id,
        TypeKey<TicketType> { type_name },
    );
    Ticket { id, `type`: *ticket_type }
}

public fun new_attribute(community: &mut Community, type_name: String, value: u64): Attribute {
    assert!(dynamic_field::exists_(&community.id, TypeKey<AttributeType> { type_name }));
    let attribute_type = dynamic_field::borrow<TypeKey<AttributeType>, AttributeType>(
        &community.id,
        TypeKey<AttributeType> { type_name },
    );
    Attribute { `type`: *attribute_type, value }
}

public fun attach_attribute(item: &mut Item, attribute: Attribute) {
    dynamic_field::add(
        &mut item.id,
        TypeKey<AttributeType> { type_name: attribute.`type`.type_name },
        attribute,
    );
}

// =======================================================
// ======================== Refactoring Functions
// =======================================================

public(package) fun update_version(community: &mut Community) {
    community.version = community.version + 1;
}

public(package) fun get_id(community: &Community): &UID {
    &community.id
}

public(package) fun get_part_type(item: &Item): &String {
    &item.`type`.part_type
}

public(package) fun make_type_key<T: store + copy + drop>(type_name: String): TypeKey<T> {
    TypeKey<T> { type_name }
}
