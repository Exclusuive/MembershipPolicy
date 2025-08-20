module exclusuive::exclusuive_membership;

use exclusuive::community::{Community, has_permission, get_uid, get_mut_uid, MembershipManager};
use std::string::String;
use sui::display;
use sui::dynamic_field;
use sui::event::emit;
use sui::package;

const ENotAuthorized: u64 = 1;
const EAlreadyExists: u64 = 2;
const EObjectNotExist: u64 = 3;

public struct MembershipType has copy, drop, store {
    community_id: ID,
    membership_name: String,
    membership_description: String,
    allow_user_mint: bool,
    allow_transfer: bool,
    version: u64,
}

public struct Membership has key, store {
    id: UID,
    community_id: ID,
    membership_name: String,
    membership_description: String,
    allow_user_mint: bool,
    allow_transfer: bool,
    image_url: String,
    version: u64,
}

public struct MembershipTypeKey<phantom Type: store + copy + drop> has copy, drop, store {
    community_id: ID,
    membership_name: String,
}

public struct EXCLUSUIVE_MEMBERSHIP has drop {}

fun init(otw: EXCLUSUIVE_MEMBERSHIP, ctx: &mut TxContext) {
    let keys = vector[b"name".to_string(), b"image_url".to_string(), b"description".to_string()];

    let values = vector[
        b"{membership_name}".to_string(),
        b"{image_url}".to_string(),
        b"{membership_description}".to_string(),
    ];

    // Claim the `Publisher` for the package!
    let publisher = package::claim(otw, ctx);

    let mut display = display::new_with_fields<Membership>(
        &publisher,
        keys,
        values,
        ctx,
    );

    // Commit first version of `Display` to apply changes.
    display.update_version();

    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_transfer(display, ctx.sender());
}

// ===== Events =====

public struct MembershipMinted has copy, drop {
    id: ID,
    membership_name: String,
    image_url: String,
}

public fun new_membership_type(
    community: &mut Community,
    membership_name: String,
    membership_description: String,
    allow_user_mint: bool,
    allow_transfer: bool,
    ctx: &mut TxContext,
) {
    let community_id = object::id(community);
    assert!(has_permission<MembershipManager>(community, tx_context::sender(ctx)), ENotAuthorized);
    assert!(
        !dynamic_field::exists_(
            get_uid(community),
            MembershipTypeKey<MembershipType> { community_id, membership_name },
        ),
        EAlreadyExists,
    );
    dynamic_field::add(
        get_mut_uid(community),
        MembershipTypeKey<MembershipType> { community_id, membership_name },
        MembershipType {
            community_id,
            membership_name,
            membership_description,
            allow_user_mint,
            allow_transfer,
            version: 0,
        },
    );
    community.update_version();
}

public fun update_membership_type(
    community: &mut Community,
    membership_name: String,
    membership_description: String,
    allow_user_mint: bool,
    allow_transfer: bool,
    ctx: &mut TxContext,
) {
    let community_id = object::id(community);

    assert!(has_permission<MembershipManager>(community, tx_context::sender(ctx)), ENotAuthorized);
    assert!(
        dynamic_field::exists_(
            get_uid(community),
            MembershipTypeKey<MembershipType> { community_id, membership_name },
        ),
        EObjectNotExist,
    );

    let membership_type = dynamic_field::borrow_mut<
        MembershipTypeKey<MembershipType>,
        MembershipType,
    >(
        get_mut_uid(community),
        MembershipTypeKey<MembershipType> { community_id, membership_name },
    );

    membership_type.allow_user_mint = allow_user_mint;
    membership_type.membership_description = membership_description;
    membership_type.allow_transfer = allow_transfer;
    membership_type.version = membership_type.version + 1;
    community.update_version();
}

public fun update_membership(
    community: &mut Community,
    membership: &mut Membership,
    ctx: &mut TxContext,
) {
    let community_id = object::id(community);
    let membership_name = membership.membership_name;
    assert!(has_permission<MembershipManager>(community, tx_context::sender(ctx)), ENotAuthorized);
    assert!(
        dynamic_field::exists_(
            get_uid(community),
            MembershipTypeKey<MembershipType> { community_id, membership_name },
        ),
        EObjectNotExist,
    );
    let membership_type = dynamic_field::borrow<MembershipTypeKey<MembershipType>, MembershipType>(
        get_uid(community),
        MembershipTypeKey<MembershipType> {
            community_id: object::id(community),
            membership_name: membership.membership_name,
        },
    );
    membership.allow_user_mint = membership_type.allow_user_mint;
    membership.membership_description = membership_type.membership_description;
    membership.allow_transfer = membership_type.allow_transfer;
    membership.version = membership_type.version;
}

public fun new_membership(
    community: &mut Community,
    membership_name: String,
    image_url: String,
    ctx: &mut TxContext,
): Membership {
    assert!(
        dynamic_field::exists_(
            get_uid(community),
            MembershipTypeKey<MembershipType> {
                community_id: object::id(community),
                membership_name,
            },
        ),
        EObjectNotExist,
    );

    let membership_type = dynamic_field::borrow<MembershipTypeKey<MembershipType>, MembershipType>(
        get_uid(community),
        MembershipTypeKey<MembershipType> {
            community_id: object::id(community),
            membership_name,
        },
    );
    assert!(
        has_permission<MembershipManager>(community, tx_context::sender(ctx))
            || membership_type.allow_user_mint,
        ENotAuthorized,
    );

    let id = object::new(ctx);

    emit(MembershipMinted {
        id: object::uid_to_inner(&id),
        membership_name,
        image_url,
    });

    Membership {
        id,
        community_id: object::id(community),
        membership_name,
        membership_description: membership_type.membership_description,
        allow_user_mint: membership_type.allow_user_mint,
        allow_transfer: membership_type.allow_transfer,
        image_url,
        version: 0,
    }
}

entry fun mint_membership(
    community: &mut Community,
    membership_name: String,
    image_url: String,
    receiver: address,
    ctx: &mut TxContext,
) {
    let membership = new_membership(community, membership_name, image_url, ctx);
    transfer::transfer(membership, receiver)
}

public fun transfer(membership: Membership, recipient: address) {
    assert!(membership.allow_transfer, ENotAuthorized);
    transfer::public_transfer(membership, recipient)
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

// ===== Public view functions =====

public fun get_membership_name(membership: &Membership): String {
    membership.membership_name
}

public fun get_membership_description(membership: &Membership): String {
    membership.membership_description
}

public fun get_membership_image_url(membership: &Membership): String {
    membership.image_url
}

public fun get_membership_allow_user_mint(membership: &Membership): bool {
    membership.allow_user_mint
}

public fun get_membership_allow_transfer(membership: &Membership): bool {
    membership.allow_transfer
}

public fun get_membership_version(membership: &Membership): u64 {
    membership.version
}

public fun get_membership_info(membership: &Membership): (String, String, String, bool, bool, u64) {
    (
        membership.membership_name,
        membership.membership_description,
        membership.image_url,
        membership.allow_user_mint,
        membership.allow_transfer,
        membership.version,
    )
}
