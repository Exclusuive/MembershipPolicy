module exclusuive::dokpami;

use std::string::{String};
use sui::package;

use exclusuive::membership_policy::{Self, Membership, MembershipPolicy, MembershipPolicyCap};

public struct DOKPAMI has drop {}

// NFT Object
public struct Dokpami has key, store {
  id: UID,
}

public struct Dokpami2 has key, store {
  id: UID,
}

// Layer
public struct BackgroundLayer has drop {}
public struct HeadLayer has drop {}
public struct BodyLayer has drop {}
public struct FootLayer has drop {}

// // Item
// public struct FireBackground has key, store {
//   id: UID
// }
// public struct SnowBackground has key, store {
//   id: UID
// }
// public struct RainBackground has key, store {
//   id: UID
// }

// Attribute
public struct Strong has drop {}
public struct Intelligence has drop {}
public struct HealthPoint has drop {}

// Ticket
public struct BasicTicket has drop {}
public struct FireTicket has drop {}
public struct IceTicket has drop {}

// Configs
public struct LayerConfig has store, copy, drop {
  description: String,
}

public struct ItemConfig has store, copy, drop {
  description: String,
}

public struct AttributeConfig has store, copy, drop {
  description: String,
}

public struct TicketConfig has store, copy, drop {
  description: String,
}

#[allow(lint(share_owned))]
fun init(otw: DOKPAMI, ctx: &mut TxContext) {
  let pub = package::claim(otw, ctx);

  let (mut policy, cap) = membership_policy::new<Dokpami>(&pub, ctx);

  membership_policy::register_layer_type(BackgroundLayer{},&mut policy, &cap, LayerConfig{description: b"background layer description".to_string()});
  membership_policy::register_layer_type(HeadLayer{},&mut policy, &cap, LayerConfig{description: b"head layer description".to_string()});
  membership_policy::register_layer_type(BodyLayer{},&mut policy, &cap, LayerConfig{description: b"body layer description".to_string()});
  membership_policy::register_layer_type(FootLayer{},&mut policy, &cap, LayerConfig{description: b"foot layer description".to_string()});

  membership_policy::register_item_type(BackgroundLayer{}, &mut policy, &cap, b"NormalBackground".to_string(), ItemConfig{description: b"item description".to_string()});
  membership_policy::register_item_type(BackgroundLayer{}, &mut policy, &cap, b"FireBackground".to_string(), ItemConfig{description: b"item description".to_string()});
  membership_policy::register_item_type(BackgroundLayer{}, &mut policy, &cap, b"IceBackground".to_string(), ItemConfig{description: b"item description".to_string()});
  membership_policy::register_item_type(HeadLayer{}, &mut policy, &cap, b"BlueCap".to_string(), ItemConfig{description: b"item description".to_string()});
  membership_policy::register_item_type(HeadLayer{}, &mut policy, &cap, b"RedCap".to_string(), ItemConfig{description: b"item description".to_string()});
  membership_policy::register_item_type(BodyLayer{}, &mut policy, &cap, b"NormalBody".to_string(), ItemConfig{description: b"item description".to_string()});
  membership_policy::register_item_type(BodyLayer{}, &mut policy, &cap, b"BlackShirtBody".to_string(), ItemConfig{description: b"item description".to_string()});
  membership_policy::register_item_type(BodyLayer{}, &mut policy, &cap, b"WhiteShirtBody".to_string(), ItemConfig{description: b"item description".to_string()});
  membership_policy::register_item_type(FootLayer{}, &mut policy, &cap, b"BlackShoes".to_string(), ItemConfig{description: b"item description".to_string()});
  membership_policy::register_item_type(FootLayer{}, &mut policy, &cap, b"WhiteShoes".to_string(), ItemConfig{description: b"item description".to_string()});

  membership_policy::register_attribute_type(Strong{}, &mut policy, &cap, AttributeConfig{description: b"Strong is ...".to_string()});
  membership_policy::register_attribute_type(Intelligence{}, &mut policy, &cap, AttributeConfig{description: b"Intelligence is ...".to_string()});
  membership_policy::register_attribute_type(HealthPoint{}, &mut policy, &cap, AttributeConfig{description: b"HealthPoint is ...".to_string()});

  membership_policy::register_ticket_type(BasicTicket{}, &mut policy, &cap, AttributeConfig{description: b"BasicTicket is ...".to_string()});
  membership_policy::register_ticket_type(FireTicket{}, &mut policy, &cap, AttributeConfig{description: b"FireTicket is ...".to_string()});
  membership_policy::register_ticket_type(IceTicket{}, &mut policy, &cap, AttributeConfig{description: b"IceTicket is ...".to_string()});

  transfer::public_share_object(policy);

  transfer::public_transfer(cap, ctx.sender());
  transfer::public_transfer(pub, ctx.sender());
}

#[allow(lint(self_transfer))]
entry fun mint_dokpami(ctx: &mut TxContext) {
  let dokpami = new_dokpami(ctx);
  transfer::transfer(dokpami, ctx.sender());
}

public fun new_dokpami(ctx: &mut TxContext): Dokpami {
  Dokpami{id: object::new(ctx)}
}

public fun mint_dokpami_with_membership(policy: &MembershipPolicy<Dokpami>, cap: &MembershipPolicyCap<Dokpami>, recipient: address, ctx: &mut TxContext) {
  assert!(object::id(policy) == cap.policy_id(), 1);
  let dokpami = new_dokpami(ctx);
  transfer::transfer(dokpami, recipient);
}

// public fun attach_membership(policy: &MembershipPolicy<Dokpami>, dokpami: &mut Dokpami, ctx: &mut TxContext) {
//   membership_policy::attach_membership(&mut dokpami.id, policy, ctx);
// }

public fun borrow_membership(base: &Dokpami, policy: &MembershipPolicy<Dokpami>): &Membership<Dokpami> {
  membership_policy::borrow_membership(&base.id, policy)
}
public fun borrow_mut_membership(base: &mut Dokpami, policy: &MembershipPolicy<Dokpami>): &mut Membership<Dokpami> {
  membership_policy::borrow_mut_membership(&mut base.id, policy)
}

// public fun test(policy: &mut MembershipPolicy<Dokpami>, cap: &MembershipPolicyCap<Dokpami>, order: u64, ctx: &mut TxContext) {
//   membership_policy::add_layer_type<Dokpami, BackgroundLayer, LayerConfig>(
//     BackgroundLayer{}, policy, cap, order, LayerConfig{description: b"".to_string()});
// }

// public fun test2(policy: &mut MembershipPolicy<Dokpami>, cap: &MembershipPolicyCap<Dokpami>, order: u64, ctx: &mut TxContext) {
//   membership_policy::add_layer_type<Dokpami, BackgroundLayer2, LayerConfig>(
//     BackgroundLayer2{}, policy, cap, order, LayerConfig{description: b"".to_string()});
// }