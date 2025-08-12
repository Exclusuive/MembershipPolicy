module exclusuive::community;

use std::string::{Self, String};
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

public struct PermissionType has copy, drop, store {
    community_id: ID,
    type_name: String,
    addr_set: VecSet<address>,
}

public struct TypeKey<phantom Type: store + copy + drop> has copy, drop, store {
    type_name: String,
}

public struct ConfigType has copy, drop, store {
    content: String,
}

// =======================================================
// ======================== Entry Functions
// =======================================================

entry fun create_community(ctx: &mut TxContext) {
    let (com, com_cap) = new_community(ctx);
    transfer::share_object(com);
    transfer::transfer(com_cap, ctx.sender());
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
    let community_id = object::id(community);
    assert!(community_id == community_cap.community_id);

    if (
        !dynamic_field::exists_<TypeKey<PermissionType>>(
            &community.id,
            TypeKey<PermissionType> { type_name },
        )
    ) {
        let mut addr_set = vec_set::empty<address>();
        vec_set::insert(&mut addr_set, addr);

        dynamic_field::add(
            &mut community.id,
            TypeKey<PermissionType> { type_name },
            PermissionType {
                community_id: community_id,
                type_name,
                addr_set,
            },
        );
    } else {
        let permission_type = dynamic_field::borrow_mut<TypeKey<PermissionType>, PermissionType>(
            &mut community.id,
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
        &mut community.id,
        TypeKey<PermissionType> { type_name },
    );
    vec_set::remove(&mut permission_type.addr_set, &addr);
    community.update_version();
}

public fun has_permission(community: &Community, type_name: String, addr: address): bool {
    if (
        !dynamic_field::exists_<TypeKey<PermissionType>>(
            &community.id,
            TypeKey<PermissionType> { type_name },
        )
    ) {
        return false
    };

    let permission_type = dynamic_field::borrow<TypeKey<PermissionType>, PermissionType>(
        &community.id,
        TypeKey<PermissionType> { type_name },
    );

    vec_set::contains(&permission_type.addr_set, &addr)
}

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

// =======================================================
// ======================== Additional Information Functions
// =======================================================

public fun new_config_type(
    community: &mut Community,
    type_name: String,
    content: String,
    ctx: &mut TxContext,
) {
    assert!(has_permission(community, string::utf8(b"community_manager"), ctx.sender()));
    assert!(!dynamic_field::exists_(&community.id, TypeKey<ConfigType> { type_name }));
    dynamic_field::add(
        &mut community.id,
        TypeKey<ConfigType> { type_name },
        ConfigType { content },
    );
    community.update_version();
}

public fun update_config_type(
    community: &mut Community,
    type_name: String,
    content: String,
    ctx: &mut TxContext,
) {
    assert!(has_permission(community, string::utf8(b"community_manager"), ctx.sender()));
    assert!(dynamic_field::exists_(&community.id, TypeKey<ConfigType> { type_name }));
    let config = dynamic_field::borrow_mut<TypeKey<ConfigType>, ConfigType>(
        &mut community.id,
        TypeKey<ConfigType> { type_name },
    );
    config.content = content;
}

// =======================================================
// ======================== Refactoring Functions
// =======================================================

public(package) fun update_version(community: &mut Community) {
    community.version = community.version + 1;
}

public(package) fun get_uid(community: &Community): &UID {
    &community.id
}

public(package) fun get_mut_uid(community: &mut Community): &mut UID {
    &mut community.id
}
