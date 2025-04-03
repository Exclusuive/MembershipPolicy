module exclusuive::membership_policy;

use std::type_name::{Self, TypeName};
use std::string::{String};

use sui::package::{Self, Publisher};
use sui::balance::{Self, Balance};
use sui::sui::{SUI};
use sui::dynamic_field;
// use sui::dynamic_object_field;
use sui::vec_map::{VecMap};
use sui::vec_set::{Self, VecSet};
use sui::bag::{Self, Bag};
// use sui::transfer_policy::{Self, RuleKey};

const ENotOwner: u64 = 100;
const ERuleAlreadySet: u64 = 101;
const ENotHasLayer: u64 = 102;
const ENotCorrectMembershipPolicy: u64 = 104;
// const EIncorrectProeprtyValue: u64 = 105;

public struct MembershipPolicy<phantom T: key> has key, store {
  id: UID,
  balance: Balance<SUI>,
  layer_types: VecSet<TypeName>,
  version: u16,
}

public struct MembershipPolicyCap<phantom T: key> has key, store {
  id: UID,
  policy_id: ID
}


// ============================================= Key 

public struct MembershipKey has store, copy, drop{}

public struct LayerKey<phantom LayerType: drop> has store, copy, drop{} // 이건 Membership 에

public struct ItemBagKey<phantom LayerType: drop> has store, copy, drop{} // 이건 Membership에

public struct PropertyKey<phantom PropertyType: drop> has store, drop, copy {} //이건 Item에

public struct TicketKey<phantom TicketType: drop> has store, drop, copy {}

public struct ConfigKey has store, copy, drop{} // 이건 item에

// public struct VendingMachineInputKey<phantom TiketType: drop> has store, copy, drop{} // 이건 item에
// public struct VendingMachineOutputKey has store, copy, drop{} // 이건 item에


// ============================================= 실제 Data & Object Structs
// Object
public struct Membership<phantom T: key> has key, store {
  id: UID,
  policy_id: ID
}

// Layer만 policy에 추가 되는 타입 데이터
public struct Layer<phantom LayerType: drop, Config: store + copy + drop> has store {
  cfg: Config,
}

public struct Property<phantom PropertyType: drop, Config: store + copy + drop> has store {
  cfg: Config
}

public struct ItemSocket<phantom LayerType: drop, Config: store + copy + drop> has store {
  socket: Option<Item<LayerType>>,
  layer: Layer<LayerType, Config>
}

// 생산 품
public struct Item<phantom LayerType: drop> has key, store {
  id: UID,
  item_type: String,
  img_url: String,
}

// 생산 품 // 요건 Item이랑 Membership에 장착하는 건데, 하나만 장착할 수 있고, 한 번만 장착 할 수 있어
public struct PropertyValue<phantom PropertyType: drop, Config: store + copy + drop> has store {
  value: u64,
  cfg: Config
}

// 생산 품
public struct Ticket<phantom TicketType: drop> has key, store {
  id: UID,
}

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
        layer_types: vec_set::empty<TypeName>(),
        version: 0,
        },
      MembershipPolicyCap<T> { id: object::new(ctx), policy_id },
  )
}

// ===================================== Membership User Function

public fun add_membership<T: key>(
    self: &mut UID,
    policy: &MembershipPolicy<T>,
    ctx: &mut TxContext,
){
  let membership = Membership<T>{id: object::new(ctx), policy_id: object::id(policy)};
  dynamic_field::add(self, MembershipKey{}, membership);
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

public fun add_item_to_membership<T: key, LayerType: drop, Config: store + copy + drop>(
    membership: &mut Membership<T>,
    item: Item<LayerType>,
    policy: &MembershipPolicy<T>,
    _: LayerType,
) {
    assert!(has_layer<T, LayerType>(policy), ENotHasLayer);

    if (!dynamic_field::exists_(&membership.id, ItemBagKey<LayerType>{})){
      dynamic_field::add(&mut membership.id, ItemBagKey<LayerType>{}, vector<Item<LayerType>>[]);
    };

    if (!dynamic_field::exists_(&membership.id, LayerKey<LayerType>{})){
      let layer = dynamic_field::borrow<LayerKey<LayerType>, Layer<LayerType, Config>>(&policy.id, LayerKey<LayerType>{});
      let item_socket = ItemSocket{
        socket: option::none(), 
        layer: Layer<LayerType, Config>{cfg: layer.cfg}
      };
      dynamic_field::add(&mut membership.id, LayerKey<LayerType>{}, item_socket);
    };

    let mut item_socket = dynamic_field::remove<LayerKey<LayerType>, ItemSocket<LayerType, Config>>(&mut membership.id, LayerKey<LayerType>{});

    if (item_socket.socket.is_some()) {
      let old_item = item_socket.socket.extract();
      let item_bag = dynamic_field::borrow_mut<ItemBagKey<LayerType>, vector<Item<LayerType>>>(&mut membership.id, ItemBagKey{});
      item_bag.push_back(old_item);
    };

    item_socket.socket.fill(item);
    dynamic_field::add(&mut membership.id, LayerKey<LayerType>{}, item_socket);
}

public fun attatch_property_to_item<LayerType: drop, PropertyType: drop, Config: store + copy + drop>(
    item: &mut Item<LayerType>,
    property: Property<PropertyType, Config>,
) {
    dynamic_field::add(&mut item.id, PropertyKey<PropertyType>{}, property);
}

// ===================================== Membership Policy Admin Functions
public fun add_layer_type<T: key, LayerType: drop, Config: store + copy + drop>(
    _: LayerType,
    policy: &mut MembershipPolicy<T>,
    cap: &MembershipPolicyCap<T>,
    cfg: Config,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_layer<T, LayerType>(policy), ERuleAlreadySet);

    let layer_type_key = type_name::get<LayerKey<LayerType>>();
    policy.layer_types.insert(layer_type_key);
    dynamic_field::add(&mut policy.id, LayerKey<LayerType> {}, Layer<LayerType, Config>{cfg});
    policy.update_version_policy();
}

public fun add_property_type<T: key, PropertyType: drop, Config: store + copy + drop>(
    _: PropertyType,
    policy: &mut MembershipPolicy<T>,
    cap: &MembershipPolicyCap<T>,
    cfg: Config,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_property<T, PropertyType>(policy), ERuleAlreadySet);

    dynamic_field::add(&mut policy.id, LayerKey<PropertyType> {}, Property<PropertyType, Config>{cfg});
    policy.update_version_policy();
}

// ===================================== Public Functions
public fun has_layer<T: key, LayerType: drop>(policy: &MembershipPolicy<T>): bool {
  dynamic_field::exists_(&policy.id, LayerKey<LayerType> {})
}
public fun has_property<T: key, PropertyType: drop>(policy: &MembershipPolicy<T>): bool {
  dynamic_field::exists_(&policy.id, PropertyKey<PropertyType> {})
}

// ============================= Public Package Functions
public (package) fun new_item_socket<T: key, LayerType: drop, Config: store + copy + drop>(
    policy: &MembershipPolicy<T>
): ItemSocket<LayerType, Config> {
  let layer = dynamic_field::borrow<LayerKey<LayerType>, Layer<LayerType, Config>>(&policy.id, LayerKey<LayerType>{});
  ItemSocket<LayerType, Config> {
    socket: option::none(),
    layer: Layer{cfg: layer.cfg}
  }
}

public (package) fun new_item<LayerType: drop, Config: store + copy + drop>(
    item_type: String,
    img_url: String,
    cfg: Config,
    ctx: &mut TxContext,
): Item<LayerType> {
    let mut item = Item<LayerType> {
      id: object::new(ctx),
      item_type,
      img_url,
    };

    dynamic_field::add(&mut item.id, ConfigKey{}, cfg);
    item
}

public (package) fun new_property_value<PropertyType: drop, Config: store + copy + drop>(
    value: u64,
    cfg: Config,
): PropertyValue<PropertyType, Config> {
  PropertyValue{ value, cfg }
}

public (package) fun new_ticket<TicketType: drop>(
    ctx: &mut TxContext,
): Ticket<TicketType> {
  Ticket<TicketType> {id: object::new(ctx)}
}

// public fun get_item_from_vendinmachine(){}

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