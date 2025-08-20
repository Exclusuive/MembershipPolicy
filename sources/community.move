module exclusuive::community;

use std::string::String;
use sui::balance::{Self, Balance};
use sui::dynamic_field;
use sui::sui::SUI;
use sui::vec_set::{Self, VecSet};

const ENotAuthorized: u64 = 2;

public struct Community has key, store {
    id: UID,
    balance: Balance<SUI>,
    version: u64,
}

public struct CommunityCap has key, store {
    id: UID,
    community_id: ID,
}

public struct PermissionType<phantom Role: store + copy + drop> has copy, drop, store {
    community_id: ID,
    addr_set: VecSet<address>,
}

public struct PermissionTypeKey<phantom Role: store + copy + drop> has copy, drop, store {
    community_id: ID,
}

public struct CommunityManager has copy, drop, store {}
public struct ItemManager has copy, drop, store {}
public struct MembershipManager has copy, drop, store {}
public struct MissionManager has copy, drop, store {}
public struct MarketManager has copy, drop, store {}

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

public fun grant_permission<Role: store + copy + drop>(
    community: &mut Community,
    community_cap: &mut CommunityCap,
    addr: address,
) {
    let community_id = object::id(community);
    assert!(community_id == community_cap.community_id);

    if (
        !dynamic_field::exists_<PermissionTypeKey<Role>>(
            &community.id,
            PermissionTypeKey<Role> { community_id },
        )
    ) {
        let mut addr_set = vec_set::empty<address>();
        vec_set::insert(&mut addr_set, addr);

        dynamic_field::add(
            &mut community.id,
            PermissionTypeKey<Role> { community_id },
            PermissionType<Role> { community_id, addr_set },
        );
    } else {
        let pv = dynamic_field::borrow_mut<PermissionTypeKey<Role>, PermissionType<Role>>(
            &mut community.id,
            PermissionTypeKey<Role> { community_id },
        );
        vec_set::insert(&mut pv.addr_set, addr);
    };
}

public fun revoke_permission<Role: store + copy + drop>(
    community: &mut Community,
    community_cap: &mut CommunityCap,
    addr: address,
) {
    let community_id = object::id(community);
    assert!(community_id == community_cap.community_id);

    if (
        !dynamic_field::exists_<PermissionTypeKey<Role>>(
            &community.id,
            PermissionTypeKey<Role> { community_id },
        )
    ) {
        return
    };

    {
        let pt = dynamic_field::borrow_mut<PermissionTypeKey<Role>, PermissionType<Role>>(
            &mut community.id,
            PermissionTypeKey<Role> { community_id },
        );
        if (vec_set::contains(&pt.addr_set, &addr)) {
            vec_set::remove(&mut pt.addr_set, &addr);
        };
    }; // <-- 여기서 pt 보로우가 스코프 아웃

    // 비었으면 동적필드 자체 제거
    {
        let pt2 = dynamic_field::borrow<PermissionTypeKey<Role>, PermissionType<Role>>(
            &community.id,
            PermissionTypeKey<Role> { community_id },
        );
        let empty = vec_set::is_empty(&pt2.addr_set);
        // pt2 drop
        if (empty) {
            let _ = dynamic_field::remove<PermissionTypeKey<Role>, PermissionType<Role>>(
                &mut community.id,
                PermissionTypeKey<Role> { community_id },
            );
        };
    };
}

public fun has_permission<Role: store + copy + drop>(community: &Community, addr: address): bool {
    let community_id = object::id(community);
    if (
        !dynamic_field::exists_<PermissionTypeKey<Role>>(
            &community.id,
            PermissionTypeKey<Role> { community_id },
        )
    ) {
        return false
    };
    let pt = dynamic_field::borrow<PermissionTypeKey<Role>, PermissionType<Role>>(
        &community.id,
        PermissionTypeKey<Role> { community_id },
    );
    vec_set::contains(&pt.addr_set, &addr)
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
    assert!(has_permission<CommunityManager>(community, tx_context::sender(ctx)), ENotAuthorized);
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
    assert!(has_permission<CommunityManager>(community, tx_context::sender(ctx)), ENotAuthorized);
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
