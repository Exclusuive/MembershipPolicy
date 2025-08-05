module exclusuive::community;

use std::string::String;
use sui::balance::{Self, Balance};
use sui::dynamic_field;
use sui::sui::SUI;
use sui::vec_set::{Self, VecSet};

public struct Community has key, store {
    id: UID,
    balance: Balance<SUI>,
    version: u64,
}

public struct CommunityCap has key, store {
    id: UID,
    community_id: ID,
}

// =======================================================
// ======================== Types
// =======================================================

public struct PermissionType has copy, drop, store {
    community_id: ID,
    type_name: String,
    addr_set: VecSet<address>,
}

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
// ======================== Admin Only Functions
// =======================================================

public fun grant_permission(
    community: &mut Community,
    community_cap: &mut CommunityCap,
    type_name: String,
    addr: address,
) {
    assert!(object::id(community) == community_cap.community_id);

    if (
        !dynamic_field::exists_<TypeKey<PermissionType>>(
            &community_cap.id,
            TypeKey<PermissionType> { type_name },
        )
    ) {
        let mut addr_set = vec_set::empty<address>();
        vec_set::insert(&mut addr_set, addr);

        dynamic_field::add(
            &mut community_cap.id,
            TypeKey<PermissionType> { type_name },
            PermissionType {
                community_id: object::id(community),
                type_name,
                addr_set,
            },
        );
    } else {
        let permission_type = dynamic_field::borrow_mut<TypeKey<PermissionType>, PermissionType>(
            &mut community_cap.id,
            TypeKey<PermissionType> { type_name },
        );
        vec_set::insert(&mut permission_type.addr_set, addr);
    };
    community.update_version();
}

public fun revoke_permission(
    community: &mut Community,
    community_cap: &mut CommunityCap,
    type_name: String,
    addr: address,
) {
    assert!(object::id(community) == community_cap.community_id);
    let permission_type = dynamic_field::borrow_mut<TypeKey<PermissionType>, PermissionType>(
        &mut community_cap.id,
        TypeKey<PermissionType> { type_name },
    );
    vec_set::remove(&mut permission_type.addr_set, &addr);
    community.update_version();
}

public fun has_permission(
    community_cap: &CommunityCap,
    type_name: String,
    ctx: &mut TxContext,
): bool {
    if (
        !dynamic_field::exists_<TypeKey<PermissionType>>(
            &community_cap.id,
            TypeKey<PermissionType> { type_name },
        )
    ) {
        return false
    };

    let permission_type = dynamic_field::borrow<TypeKey<PermissionType>, PermissionType>(
        &community_cap.id,
        TypeKey<PermissionType> { type_name },
    );

    vec_set::contains(&permission_type.addr_set, &ctx.sender())
}

// =======================================================
// ======================== Register Type Functions
// =======================================================

public fun new_community(ctx: &mut TxContext): (Community, CommunityCap) {
    let community = Community {
        id: object::new(ctx),
        balance: balance::zero(),
        version: 0,
    };
    let community_cap = CommunityCap {
        id: object::new(ctx),
        community_id: object::id(&community),
    };
    (community, community_cap)
}

public fun register_membership_type(
    community: &mut Community,
    community_cap: &CommunityCap,
    type_name: String,
    ctx: &mut TxContext,
) {
    assert!(has_permission(community_cap, b"membership".to_string(), ctx));
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
    community_cap: &CommunityCap,
    membership_type: String,
    type_name: String,
    ctx: &mut TxContext,
) {
    assert!(has_permission(community_cap, b"membership".to_string(), ctx));
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
    community_cap: &CommunityCap,
    membership_type: String,
    part_type: String,
    type_name: String,
    image_url: String,
    ctx: &mut TxContext,
) {
    assert!(has_permission(community_cap, b"item".to_string(), ctx));

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

public fun register_attribute_type(
    community: &mut Community,
    community_cap: &CommunityCap,
    type_name: String,
    ctx: &mut TxContext,
) {
    assert!(has_permission(community_cap, b"item".to_string(), ctx));
    let community_id = object::id(community);
    dynamic_field::add(
        &mut community.id,
        TypeKey<AttributeType> { type_name },
        AttributeType { community_id, type_name },
    );
    community.update_version();
}

public fun register_ticket_type(
    community: &mut Community,
    community_cap: &CommunityCap,
    type_name: String,
    ctx: &mut TxContext,
) {
    assert!(has_permission(community_cap, b"ticket".to_string(), ctx));
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
