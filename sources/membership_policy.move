module exclusuive::membership_policy;

use std::type_name::{TypeName};
use std::string::{String};

use sui::package::{Self, Publisher};
use sui::balance::{Self, Balance};
use sui::sui::{SUI};
use sui::dynamic_field;
use sui::dynamic_object_field;
// use sui::transfer_policy::{Self, RuleKey};

const ENotOwner: u64 = 100;
const ERuleAlreadySet: u64 = 101;
const ENotHasLayer: u64 = 102;
const ENotCorrectMembershipPolicy: u64 = 104;
const EIncorrectProeprtyValue: u64 = 105;

public struct MembershipPolicy<phantom T: key> has key, store {
  id: UID,
  balance: Balance<SUI>,
  version: u16,
}
public struct MembershipPolicyCap<phantom T: key> has key, store {
  id: UID,
  policy_id: ID
}

public struct Condition<phantom T: key> has key, store {
  id: UID,
  policy_id: ID
}

public struct ConditionCap<phantom T: key> has key, store {
  id: UID,
  condition_id: ID
}


// ============================================= Key & Config
public struct MembershipKey has store, copy, drop{}

public struct LayerTypeKey<phantom LayerType: drop> has store, copy, drop{}

// ItemKey {item_type: "type1"} 과 ItemKey {item_type: "type1"} 가 '동알하게 인식 되면 => OK' '다르게 인식 되면 => Not OK'
public struct ItemTypeKey<phantom LayerType: drop> has store, copy, drop {
  item_type: String
}

public struct PropertyTypeKey<phantom PropertyType: drop> has store, drop, copy {}

public struct LayerConfig<phantom LayerType: drop, Config: store + copy + drop> has store, copy, drop {
  order: u64,
  cfg: Config,
}

public struct ItemConfig<phantom LayerType: drop, Config: store + copy + drop> has store, copy, drop {
  item_type: String,
  img_url: String,
  cfg: Config,
}

public struct PropertyConfig<phantom PropertyType: drop, Config: store + copy + drop> has store, copy, drop {
  min: u64,
  max: u64,
  cfg: Config,
}

// ============================================= 실제 Data & Object Structs

// Object
public struct Ticket<phantom T: key, phantom TicketType: drop> has key, store {
  id: UID
}

// Object
public struct Membership<phantom T: key> has key, store {
  id: UID,
  policy_id: ID
}

public struct Layer<phantom T: key, phantom LayerType: drop, LConfig: store + copy + drop, IConfig: store + copy + drop> has store {
  item_socket: Option<Item<T, LayerType, IConfig>>,
  cfg: LayerConfig<LayerType, LConfig>,
}

// Object
public struct Item<phantom T: key, phantom LayerType: drop, Config: store + copy + drop> has key, store {
  id: UID,
  cfg: ItemConfig<LayerType, Config>,
}
// Property는 Item에만 있는게 아니라, Membership에도 넣는게 놓을까
public struct Property<phantom T: key, phantom PropertyType: drop, Config: store + copy + drop> has store {
  value: u64,
  cfg: PropertyConfig<PropertyType, Config>
}

// =========================================

// public struct CollectionRequest<phantom T: key> {}

// public struct ConvertRequest<phantom T: key> {}


// -------------------------- Admin Functions

public fun new<T: key>(pub: &Publisher, ctx: &mut TxContext): (MembershipPolicy<T>, MembershipPolicyCap<T>){
  assert!(package::from_package<T>(pub), 0);

  let id = object::new(ctx);
  let policy_id = id.to_inner();
  // event::emit(MembershipPolicyCreated<T> { id: policy_id });
  (
      MembershipPolicy<T> { 
        id, 
        balance: balance::zero(),
        version: 0,
        },
      MembershipPolicyCap<T> { id: object::new(ctx), policy_id },
  )
}

// ===================================== Admin Package Functions for Membership User

public fun add_membership<T: key>(
    self: &mut UID,
    policy: &MembershipPolicy<T>,
    ctx: &mut TxContext,
){
  dynamic_field::add(self, MembershipKey{}, Membership<T>{id: object::new(ctx), policy_id: object::id(policy)});
}

public fun borrow_membership<T: key>(
    self: &UID,
    policy: &MembershipPolicy<T>
): &Membership<T>{
  let membership = dynamic_field::borrow<MembershipKey, Membership<T>>(self, MembershipKey{});
  assert!(object::id(policy) == membership.policy_id, ENotCorrectMembershipPolicy);
  membership
}

public fun borrow_mut_membership<T: key>(
    self: &mut UID,
    policy: &MembershipPolicy<T>
): &mut Membership<T>{
  let membership = dynamic_field::borrow_mut<MembershipKey, Membership<T>>(self, MembershipKey{});
  assert!(object::id(policy) == membership.policy_id, ENotCorrectMembershipPolicy);
  membership
}

// LayerType 당 하나 씩 구현해야 함
public fun add_layer_to_membership<T: key, LayerType: drop, LConfig: store + copy + drop, IConfig: store + copy + drop>(
    membership: &mut Membership<T>,
    policy: &MembershipPolicy<T>,
    _: LayerType,
) {
    assert!(has_layer<T, LayerType>(policy), ENotHasLayer);

    if (dynamic_field::exists_<LayerTypeKey<LayerType>>(&membership.id, LayerTypeKey<LayerType>{})){
      return
    };

    let cfg = dynamic_field::borrow<LayerTypeKey<LayerType>, LayerConfig<LayerType, LConfig>>( &policy.id, LayerTypeKey<LayerType> {});
    let layer = Layer<T, LayerType, LConfig, IConfig>{item_socket: option::none(),cfg: *cfg};
    dynamic_field::add<LayerTypeKey<LayerType>, Layer<T, LayerType, LConfig, IConfig>>(&mut membership.id, LayerTypeKey<LayerType>{}, layer);
}

public fun add_property_to_membership<T: key, PropertyType: drop, Config: store + copy + drop>(
    membership: &mut Membership<T>,
    policy: &MembershipPolicy<T>,
    _: PropertyType,
    value: u64,
) {
    assert!(has_property<T, PropertyType>(policy), ENotHasLayer);

    let cfg = dynamic_field::borrow<PropertyTypeKey<PropertyType>, PropertyConfig<PropertyType, Config>>( &policy.id, PropertyTypeKey<PropertyType> {});
    assert!(cfg.min <= value && value <= cfg.max, EIncorrectProeprtyValue);

    if(dynamic_field::exists_<PropertyTypeKey<PropertyType>>(&membership.id, PropertyTypeKey<PropertyType>{})){
      let old_property = dynamic_field::remove<PropertyTypeKey<PropertyType>, Property<T, PropertyType, Config>>(&mut membership.id, PropertyTypeKey<PropertyType>{});
      let Property {value:_, cfg: _} = old_property;
    };

    let property = Property<T, PropertyType, Config>{value, cfg: *cfg};
    dynamic_field::add<PropertyTypeKey<PropertyType>, Property<T, PropertyType, Config>>(&mut membership.id, PropertyTypeKey<PropertyType>{}, property);
}

// ===================================== Admin Functions
public fun add_layer_type<T: key, LayerType: drop, Config: store + copy + drop>(
    _: LayerType,
    policy: &mut MembershipPolicy<T>,
    cap: &MembershipPolicyCap<T>,
    order: u64,
    cfg: Config,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_layer<T, LayerType>(policy), ERuleAlreadySet);

    add_layer_type_internal(&mut policy.id, _, order, cfg);
    policy.update_version_policy();
}

public fun add_item_type<T: key, LayerType: drop, Config: store + copy + drop>(
    _: LayerType,
    policy: &mut MembershipPolicy<T>,
    cap: &MembershipPolicyCap<T>,
    item_type: String,
    img_url: String,
    cfg: Config,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_item<T, LayerType>(policy, item_type), ERuleAlreadySet);

    add_item_type_internal(&mut policy.id, _, item_type, img_url, cfg);
    policy.update_version_policy();
}

public fun add_property_type<T: key, PropertyType: drop, Config: store + copy + drop>(
    _: PropertyType,
    policy: &mut MembershipPolicy<T>,
    cap: &MembershipPolicyCap<T>,
    min: u64,
    max: u64,
    cfg: Config,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_property<T, PropertyType>(policy), ERuleAlreadySet);

    add_property_type_internal(&mut policy.id, _, min, max, cfg);
    policy.update_version_policy();
}


// ===================================== Public Functions
public fun has_layer<T: key, LayerType: drop>(policy: &MembershipPolicy<T>): bool {
  dynamic_field::exists_(&policy.id, LayerTypeKey<LayerType> {})
}
public fun has_item<T: key, LayerType: drop>(policy: &MembershipPolicy<T>, item_type: String): bool {
  dynamic_object_field::exists_(&policy.id, ItemTypeKey<LayerType> {item_type})
}
public fun has_property<T: key, PropertyType: drop>(policy: &MembershipPolicy<T>): bool {
  dynamic_field::exists_(&policy.id, PropertyTypeKey<PropertyType> {})
}

// ============================= Public Package Functions
public (package) fun add_layer_type_internal<LayerType: drop, Config: store + copy + drop>(
    self: &mut UID,
    _: LayerType,
    order: u64,
    cfg: Config,
) {
    dynamic_field::add<LayerTypeKey<LayerType>, LayerConfig<LayerType,Config>>( self, LayerTypeKey<LayerType> {}, LayerConfig{order, cfg});
}

public (package) fun add_item_type_internal<LayerType: drop, Config: store + copy + drop>(
    self: &mut UID,
    _: LayerType,
    item_type: String,
    img_url: String,
    cfg: Config,
) {
    let item_config = ItemConfig<LayerType, Config>{ item_type, img_url, cfg};
    dynamic_field::add(self, ItemTypeKey<LayerType> {item_type}, item_config);
}

public (package) fun add_property_type_internal<PropertyType: drop, Config: store + copy + drop>(
    self: &mut UID,
    _: PropertyType,
    min: u64,
    max: u64,
    cfg: Config,
) {

    let property_config = PropertyConfig<PropertyType, Config>{ cfg, min, max};
    dynamic_field::add(self, PropertyTypeKey<PropertyType> {}, property_config);
}

public (package) fun update_version_policy<T: key>(policy: &mut MembershipPolicy<T>) {
  policy.version = policy.version + 1;
}
public (package) fun get_struct_name(self: TypeName): String {
    let ascii_colon: u8 = 58;
    let ascii_less_than: u8 = 60;
    let ascii_greater_than: u8 = 62;

    let mut str_bytes = self.into_string().into_bytes();
    let mut struct_name = vector<u8>[];
    loop {
        let char = str_bytes.pop_back<u8>();
        if (char == ascii_less_than || char == ascii_greater_than) {
          continue
        }else if (char != ascii_colon ) {
          struct_name.push_back(char);
        } else {
            break
        }
    };

    struct_name.reverse();
    struct_name.to_string()
}