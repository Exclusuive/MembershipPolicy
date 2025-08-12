// module exclusuive::v1_membership;

// use std::string::String;
// use sui::clock::Clock;
// use sui::dynamic_field as df;
// use sui::event::emit;
// use sui::package;
// use sui::tx_context::sender;

// /// Trying to perform an action when not authorized.
// const ENotAuthorized: u64 = 0;
// /// Does not comply to cohort limitation regarding max minting time.
// const ENotCohortTimeCompliant: u64 = 1;
// /// Does not comply to cohort limitation regarding max minting quantity.
// const ENotCohortQuantityCompliant: u64 = 2;

// // ======== Types =========

// public struct MembershipType has copy, drop, store {
//     community_id: ID,
//     type_name: String,
// }

// /// The `Membership` type - the main type of the `membership`
// /// package which contains all common attributes.
// public struct Membership<phantom T> has key, store {
//     id: UID,
//     membership_type: MembershipType,
//     image_url: String,
//     start_time: u64,
//     end_time: u64,
// }

// /// Capability granting mint permission.
// public struct MintCap has drop, store {
//     community_id: ID,
//     created_by: String,
//     membership_type: MembershipType,
//     time_limit: u64,
//     minting_limit: u64,
//     minting_counter: u64,
// }

// /// Event. When new Capy is born.
// public struct MembershipMinted has copy, drop {
//     id: ID,
//     community_id: ID,
//     created_by: String,
//     membership_type: MembershipType,
//     image_url: String,
// }

// public struct AdminCap has key, store { id: UID }

// public struct MintKey<phantom T> has copy, drop, store {}

// public struct V1_MEMBERSHIP has drop {}

// fun init(otw: V1_MEMBERSHIP, ctx: &mut TxContext) {
//     package::claim_and_keep(otw, ctx);
//     transfer::transfer(AdminCap { id: object::new(ctx) }, sender(ctx));
// }

// public fun mint<T>(
//     app: &mut UID,
//     membership_type: MembershipType,
//     image_url: String,
//     clock: &Clock,
//     ctx: &mut TxContext,
// ): Membership<T> {
//     assert!(is_authorized<T>(app), ENotAuthorized);

//     let mint_cap = mint_cap_mut<T>(app);

//     assert!((sui::clock::timestamp_ms(clock) <= mint_cap.time_limit), ENotCohortTimeCompliant);
//     assert!((mint_cap.minting_counter < mint_cap.minting_limit), ENotCohortQuantityCompliant);

//     mint_cap.minting_counter = mint_cap.minting_counter + 1;

//     let id = object::new(ctx);

//     emit(MembershipMinted {
//         id: object::uid_to_inner(&id),
//         community_id: mint_cap.community_id,
//         created_by: mint_cap.created_by,
//         membership_type: mint_cap.membership_type,
//         image_url: image_url,
//     });

//     Membership {
//         id,
//         membership_type,
//         image_url,
//     }
// }

// /// Unpack the `Membership` object and return UID for dynamic fields processing.
// public fun burn<T>(app: &mut UID, membership: Membership<T>): UID {
//     assert!(is_authorized<T>(app), ENotAuthorized);
//     let Membership {
//         id,
//         membership_type: _,
//         image_url: _,
//     } = membership;
//     id
// }

// // === Authorization ===

// public fun authorize_app<T>(
//     _: &AdminCap,
//     app: &mut UID,
//     community_id: ID,
//     created_by: String,
//     membership_type: MembershipType,
//     time_limit: u64,
//     minting_limit: u64,
// ) {
//     df::add(
//         app,
//         MintKey<T> {},
//         MintCap {
//             community_id,
//             created_by,
//             membership_type,
//             time_limit,
//             minting_limit,
//             minting_counter: 0,
//         },
//     )
// }

// public fun revoke_auth<T>(_: &AdminCap, app: &mut UID) {
//     let MintCap {
//         community_id: _,
//         created_by: _,
//         membership_type: _,
//         time_limit: _,
//         minting_limit: _,
//         minting_counter: _,
//     } = df::remove(app, MintKey<T> {});
// }

// /// Check whether an Application has a permission to mint or
// /// burn a specific Membership<T>.
// public fun is_authorized<T>(app: &UID): bool {
//     df::exists_<MintKey<T>>(app, MintKey {})
// }

// public fun mint_cap_mut<T>(app: &mut UID): &mut MintCap {
//     df::borrow_mut<MintKey<T>, MintCap>(app, MintKey {})
// }
