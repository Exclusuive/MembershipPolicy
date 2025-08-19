module exclusuive::membership;

use exclusuive::community::{Community, has_permission, get_uid, get_mut_uid, MembershipManager};
use std::string::String;
use sui::dynamic_field;
use sui::event::emit;

const ENotAuthorized: u64 = 2;

public struct MembershipType has copy, drop, store {
    community_id: ID,
    mode: u8,
    type_name: String,
}

// mode 0 : Do not allow user to mint membership
// mode 1 : Allow User to Mint Membership

public struct Membership has key, store {
    id: UID,
    community_id: ID,
    membership_type: String,
    image_url: String,
}

public struct MembershipTypeKey<phantom Type: store + copy + drop> has copy, drop, store {
    community_id: ID,
    type_name: String,
}

public struct MembershipMinted has copy, drop {
    id: ID,
    membership_type: String,
    image_url: String,
}

entry fun mint_membership(
    community: &Community,
    type_name: String,
    image_url: String,
    receiver: address,
    ctx: &mut TxContext,
) {
    let community_id = object::id(community);
    assert!(
        dynamic_field::exists_(
            get_uid(community),
            MembershipTypeKey<MembershipType> { community_id, type_name },
        ),
    );

    let membership_type = dynamic_field::borrow<MembershipTypeKey<MembershipType>, MembershipType>(
        get_uid(community),
        MembershipTypeKey<MembershipType> { community_id, type_name },
    );

    assert!(
        has_permission<MembershipManager>(community, tx_context::sender(ctx))
            || membership_type.mode == 1,
        ENotAuthorized,
    );

    let id = object::new(ctx);

    emit(MembershipMinted {
        id: object::uid_to_inner(&id),
        membership_type: type_name,
        image_url,
    });

    let membership = Membership {
        id,
        community_id: object::id(community),
        membership_type: type_name,
        image_url,
    };

    transfer::transfer(membership, receiver)
}

public fun new_membership_type(
    community: &mut Community,
    type_name: String,
    mode: u8,
    ctx: &mut TxContext,
) {
    let community_id = object::id(community);
    assert!(has_permission<MembershipManager>(community, tx_context::sender(ctx)), ENotAuthorized);
    assert!(
        !dynamic_field::exists_(
            get_uid(community),
            MembershipTypeKey<MembershipType> { community_id, type_name },
        ),
    );
    dynamic_field::add(
        get_mut_uid(community),
        MembershipTypeKey<MembershipType> { community_id, type_name },
        MembershipType { community_id, type_name, mode },
    );
    community.update_version();
}

public fun new_membership(
    community: &mut Community,
    type_name: String,
    image_url: String,
    ctx: &mut TxContext,
): Membership {
    assert!(
        dynamic_field::exists_(
            get_uid(community),
            MembershipTypeKey<MembershipType> { community_id: object::id(community), type_name },
        ),
    );
    let membership_type = dynamic_field::borrow<MembershipTypeKey<MembershipType>, MembershipType>(
        get_uid(community),
        MembershipTypeKey<MembershipType> {
            community_id: object::id(community),
            type_name,
        },
    );

    assert!(
        has_permission<MembershipManager>(community, tx_context::sender(ctx))
            || membership_type.mode == 1,
        ENotAuthorized,
    );
    let id = object::new(ctx);

    emit(MembershipMinted {
        id: object::uid_to_inner(&id),
        membership_type: type_name,
        image_url,
    });

    Membership {
        id,
        community_id: object::id(community),
        membership_type: type_name,
        image_url,
    }
}

public(package) fun get_mut_uid_membership(membership: &mut Membership): &mut UID {
    &mut membership.id
}

public(package) fun get_uid_membership(membership: &Membership): &UID {
    &membership.id
}

public(package) fun community_id(membership: &Membership): ID {
    membership.community_id
}

public fun get_membership_type(membership: &Membership): String {
    membership.membership_type
}
