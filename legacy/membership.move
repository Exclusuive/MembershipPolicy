// module exclusuive::membership;

// use exclusuive::community::{
//     Community,
//     MembershipType,
//     PartType,
//     Item,
//     TypeKey,
//     get_id,
//     make_type_key,
//     get_part_type
// };
// use std::string::String;
// use sui::dynamic_field;

// public struct Membership has key, store {
//     id: UID,
//     `type`: MembershipType,
//     img_url: String,
// }

// public struct ItemKey<phantom Type: key + store> has copy, drop, store {
//     type_name: String,
// }

// public fun new_membership(
//     community: &mut Community,
//     type_name: String,
//     img_url: String,
//     ctx: &mut TxContext,
// ): Membership {
//     let id = object::new(ctx);
//     assert!(dynamic_field::exists_(get_id(community), make_type_key<MembershipType>(type_name)));
//     let membership_type = dynamic_field::borrow<TypeKey<MembershipType>, MembershipType>(
//         get_id(community),
//         make_type_key<MembershipType>(type_name),
//     );
//     Membership {
//         id,
//         `type`: *membership_type,
//         img_url,
//     }
// }

// #[allow(lint(self_transfer))]
// public fun equip_item_to_membership(
//     community: &mut Community,
//     membership: &mut Membership,
//     item: Item,
//     ctx: &mut TxContext,
// ) {
//     let part_type = get_part_type(&item);
//     assert!(
//         dynamic_field::exists_(
//             get_id(community),
//             make_type_key<PartType>(*part_type),
//         ),
//     );

//     if (
//         !dynamic_field::exists_<ItemKey<Item>>(
//             &membership.id,
//             ItemKey<Item> { type_name: *part_type },
//         )
//     ) {
//         dynamic_field::add(
//             &mut membership.id,
//             ItemKey<Item> { type_name: *part_type },
//             item,
//         );
//     } else {
//         let old_item: Item = dynamic_field::remove(
//             &mut membership.id,
//             ItemKey<Item> { type_name: *part_type },
//         );

//         dynamic_field::add(
//             &mut membership.id,
//             ItemKey<Item> { type_name: *part_type },
//             item,
//         );
//         transfer::public_transfer(old_item, ctx.sender());
//     };
// }
