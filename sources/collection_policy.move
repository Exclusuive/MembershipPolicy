module exclusuive::collection_policy;

use std::type_name::{Self, TypeName};
use std::string::{String};

use sui::package::{Publisher};
use sui::balance::{Balance};
use sui::sui::{SUI};
use sui::vec_set::{VecSet};
use sui::dynamic_field;

// add collection property? collection info?
public struct CollectionPolicy<phantom T> has key {
  id: UID,
  name: String,
  description: String,
  layers: VecSet<LayerInfo<T>>,
  items: VecSet<ItemInfo<T>>,
  properties: VecSet<PropertyInfo<T>>,
  rules: VecSet<TypeName>,
  balance: Balance<SUI>,
}

public struct CollectionPolicyCap<phantom T> has key, store {
  id: UID,
  `for`: ID
}

public struct LayerInfo<phantom T> has copy, store, drop {
  name: String,
  description: String,
  order: u64,
}

public struct ItemInfo<phantom T> has copy, store, drop {
  layer: LayerInfo<T>,
  name: String,
  description: String,
  image_url: String,
}

public struct PropertyInfo<phantom T> has copy, store, drop {
  layer: LayerInfo<T>,
  name: String,
  description: String,
}

public struct CollectionRequest<phantom T> {
  // item
  // paid
  // from
  // receipts
}

// 이건 사용자 Custom 으로 각 사용자 패키지에서 만들어야 할 것 같은데??
// public struct Base<phantom T> has key, store {
//   id: UID,
// }

// 이건 add_layer 할 때 생성 
public struct Layer<phantom T> has key, store {
  id: UID,
  info: LayerInfo<T>,
  item_socket: Option<Item<T>>
}

// 이건 add_item 할 때 생성
public struct Item<phantom T> has key, store {
  id: UID,
  info: ItemInfo<T>,
  properties: vector<Property<T>>,
}

// 이건 add_property 할 때 생성
public struct Property<phantom T> has store {
  info: PropertyInfo<T>,
  value: u64,
}


public fun new<T>(pub: &Publisher, ctx: &mut TxContext){}

public fun add_rule<T>(policy: &mut CollectionPolicy<T>) {}

// public fun add_rule<T, Rule: drop, Config: store + drop>(
//     _: Rule,
//     policy: &mut TransferPolicy<T>,
//     cap: &TransferPolicyCap<T>,
//     cfg: Config,
// ) {
//     assert!(object::id(policy) == cap.policy_id, ENotOwner);
//     assert!(!has_rule<T, Rule>(policy), ERuleAlreadySet);
//     dynamic_field::add(&mut policy.id, RuleKey<Rule> {}, cfg);
//     policy.rules.insert(type_name::get<Rule>())
// }

public fun add_layer<T>(policy: &mut CollectionPolicy<T>) {}

public fun add_item<T>(policy: &mut CollectionPolicy<T>) {}

public fun add_property<T>(policy: &mut CollectionPolicy<T>) {}


