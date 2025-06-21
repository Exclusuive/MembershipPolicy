module exclusuive::dokpami;

use std::string::{String};
use sui::package;

use exclusuive::membership_policy::{Self,Membership, MembershipPolicy, MembershipPolicyCap};

public struct DOKPAMI has drop {}

////////// -----------
public struct OldNFT has key, store {
  id: UID,
}

/////////// -----------
public struct Dokpami has key, store {
  id: UID,
}

public struct DokpamiItem<phantom T> has key, store {
  id: UID,
}

// Layer
public struct BackgroundLayer has store, drop {}
public struct HeadLayer has store, drop {}
public struct BodyLayer has store, drop {}
public struct FootLayer has store, drop {}

// Item
public struct FireBackground has key, store {
  id: UID
}
public struct SnowBackground has key, store {
  id: UID
}
public struct RainBackground has key, store {
  id: UID
}

public struct Character1 has key, store {
  id: UID
}

public struct Character2 has key, store {
  id: UID
}

// Property
public struct StrProperty has drop {}
public struct IntProperty has drop {}

// Configs
public struct LayerConfig has store, drop {
  description: String,
  // sub_descir: String,
}

public struct ItemConfig has store, drop {
  description: String,
  sub_descir: String,
}

public struct PropertyConfig has store, drop {
  description: String,
  sub_descir: String,
}

#[allow(lint(share_owned))]
fun init(otw: DOKPAMI, ctx: &mut TxContext) {
  let pub = package::claim(otw, ctx);

  let (mempol, cap) = membership_policy::new<Dokpami>(&pub, ctx);

  transfer::public_share_object(mempol);

  transfer::public_transfer(cap, ctx.sender());
  transfer::public_transfer(pub, ctx.sender());
}

#[allow(lint(self_transfer))]
public fun default(ctx: &mut TxContext) {
  transfer::transfer(Dokpami{id: object::new(ctx)}, ctx.sender());
}

public fun new(ctx: &mut TxContext): Dokpami {
  Dokpami{id: object::new(ctx)}
}

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