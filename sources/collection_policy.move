module exclusuive::collection_policy;

use std::type_name::{Self, TypeName};
use std::string::{String};

use sui::package::{Self, Publisher};
use sui::balance::{Self, Balance};
use sui::sui::{SUI};
use sui::vec_set::{Self, VecSet};
use sui::dynamic_field;
use sui::dynamic_object_field;
// use sui::transfer_policy;

const ENotOwner: u64 = 100;
const ERuleAlreadySet: u64 = 101;

// Shared
public struct CollectionPolicy<phantom T: key> has key {
  id: UID,
  layers: VecSet<TypeName>,
  items: VecSet<TypeName>,
  properties: VecSet<TypeName>,
  rules: VecSet<TypeName>,
  balance: Balance<SUI>,
}

// Owned
public struct CollectionPolicyCap<phantom T: key> has key, store {
  id: UID,
  policy_id: ID
}

public struct CollectionRequest<phantom T: key> {
  // item
  // paid
  // from
  // receipts
}

// --------------------------------------------------------------

public struct LayerKey<phantom T, phantom LayerType: drop, phantom CustomConfig: store + drop> has store, drop, copy {}

public struct LayerConfig<phantom T, phantom LayerType: drop, CustomConfig: store + drop> has store, drop {
  order: u64,
  cfg: CustomConfig,
}

public struct ItemKey<phantom T, phantom LayerType: drop, phantom CustomConfig: store + drop> has store, drop, copy {
  name: String
}

public struct ItemConfig<phantom T, phantom LayerType: drop, CustomConfig: store + drop> has store, drop {
  name: String,
  img_url: String,
  cfg: CustomConfig,
}

public struct PropertyKey<phantom T, phantom PropertyType: drop> has store, drop, copy {}

public struct PropertyConfig<phantom T: key, phantom PropertyType: drop, CustomConfig: store + drop> has store, drop {
  min: u64,
  max: u64,
  cfg: CustomConfig,
}

public struct RuleKey<phantom T: key, phantom Rule: drop> has copy, drop, store {}

//------------------------------------------------- 실제 Object Structs

// owned by df
public struct Layer<phantom T: key, phantom LayerType: drop, CustomConfig: store + drop > has store {
  item_socket: Option<Item<T, LayerType, CustomConfig>>
}

// owned by dof
public struct Item<phantom T: key, phantom LayerType: drop, CustomConfig: store + drop> has key, store {
  id: UID,
  cfg: ItemConfig<T, LayerType, CustomConfig>,
}

// owned by df
public struct Property<phantom T: key, phantom PropertyType: drop, CustomConfig: store + drop> has store {
  value: u64,
  cfg: PropertyConfig<T, PropertyType, CustomConfig>
}


// -------------------------- Admin Functions

public fun new<T: key>(pub: &Publisher, ctx: &mut TxContext): (CollectionPolicy<T>, CollectionPolicyCap<T>){
  assert!(package::from_package<T>(pub), 0);

  let id = object::new(ctx);
  let policy_id = id.to_inner();
  // event::emit(CollectionPolicyCreated<T> { id: policy_id });
  (
      CollectionPolicy<T> { id, layers: vec_set::empty(), items: vec_set::empty(), properties: vec_set::empty(), rules: vec_set::empty(), balance: balance::zero() },
      CollectionPolicyCap<T> { id: object::new(ctx), policy_id },
  )
}

public fun add_layer_type<T: key, LayerType: drop, CustomConfig: store + drop>(
    _: LayerType,
    policy: &mut CollectionPolicy<T>,
    cap: &CollectionPolicyCap<T>,
    order: u64,
    cfg: CustomConfig,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_layer<T, LayerType, CustomConfig>(policy), ERuleAlreadySet);

    let layer_config = LayerConfig<T, LayerType, CustomConfig>{order, cfg};
    dynamic_field::add(&mut policy.id, LayerKey<T, LayerType, CustomConfig> {}, layer_config);
    policy.layers.insert(type_name::get<LayerKey<T, LayerType, CustomConfig>>())
}

public fun add_item_type<T: key, LayerType: drop, CustomConfig: store + drop>(
    _: LayerType,
    policy: &mut CollectionPolicy<T>,
    cap: &CollectionPolicyCap<T>,
    name: String,
    img_url: String,
    cfg: CustomConfig,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_item<T, LayerType, CustomConfig>(policy, name), ERuleAlreadySet);

    let item_config = ItemConfig<T, LayerType, CustomConfig>{name, img_url, cfg};
    dynamic_field::add(&mut policy.id, ItemKey<T, LayerType, CustomConfig> {name}, item_config);
    policy.items.insert(type_name::get<ItemKey<T, LayerType, CustomConfig>>())
}

public fun add_property_type<T: key, PropertyType: drop, CustomConfig: store + drop>(
    _: PropertyType,
    policy: &mut CollectionPolicy<T>,
    cap: &CollectionPolicyCap<T>,
    min: u64,
    max: u64,
    cfg: CustomConfig,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_property<T, PropertyType>(policy), ERuleAlreadySet);

    let property_config = PropertyConfig<T, PropertyType, CustomConfig>{min, max, cfg};
    dynamic_field::add(&mut policy.id, PropertyKey<T, PropertyType> {}, property_config);
    policy.properties.insert(type_name::get<PropertyKey<T, PropertyType>>())
}

public fun add_rule<T: key, Rule: drop, CustomConfig: store + drop>(
    _: Rule,
    policy: &mut CollectionPolicy<T>,
    cap: &CollectionPolicyCap<T>,
    cfg: CustomConfig,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_rule<T, Rule>(policy), ERuleAlreadySet);
    dynamic_field::add(&mut policy.id, RuleKey<T, Rule> {}, cfg);
    policy.rules.insert(type_name::get<RuleKey<T, Rule>>())
}

// --------------------------------------------- Public Functions
public fun has_layer<T: key, LayerType: drop, CustomConfig: store + drop>(policy: &CollectionPolicy<T>): bool {
  dynamic_field::exists_(&policy.id, LayerKey<T, LayerType, CustomConfig> {})
}
public fun has_item<T: key, LayerType: drop, CustomConfig: store + drop>(policy: &CollectionPolicy<T>, name: String): bool {
  // 될라나?
  dynamic_object_field::exists_(&policy.id, ItemKey<T, LayerType, CustomConfig> {name})
}
public fun has_property<T: key, PropertyType: drop>(policy: &CollectionPolicy<T>): bool {
  dynamic_field::exists_(&policy.id, PropertyKey<T, PropertyType> {})
}
public fun has_rule<T: key, Rule: drop>(policy: &CollectionPolicy<T>): bool {
  dynamic_field::exists_(&policy.id, RuleKey<T, Rule> {})
}
