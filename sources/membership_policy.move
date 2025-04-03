module exclusuive::membership_policy;

use std::type_name::{Self, TypeName};
use std::string::{String};

use sui::package::{Self, Publisher};
use sui::balance::{Self, Balance};
use sui::coin::{Coin};
use sui::sui::{SUI};
use sui::dynamic_field;
// use sui::dynamic_object_field;
use sui::vec_map::{Self, VecMap};
use sui::vec_set::{Self, VecSet};
// use sui::bag::{Self, Bag};
// use sui::transfer_policy::{Self, RuleKey};

const ENotOwner: u64 = 100;
const ERuleAlreadySet: u64 = 101;
const ENotHasLayer: u64 = 102;
const ENotCorrectMembershipPolicy: u64 = 104;
const EIllegalRule: u64 = 105;
const ENotCorrectVendingMachine: u64 = 106;
const ENotEnoughPaid: u64 = 107;


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

public struct VendingMachine<phantom T: key> has key, store {
  id: UID,
  policy_id: ID,
  selections: vector<Selection>,
  size: u64,
  balance: Balance<SUI>,
}

public struct VendingMachineCap<phantom T: key> has key, store {
  id: UID,
  machine_id: ID
}

// 이게 Inputs, 즉 Rules, 즉, Condition
public struct Selection has store {
  conditions: vector<Condition>,
  price: u64,
  product: TypeName
}

public struct Condition has store, copy, drop {
  ticket_type: TypeName,
  requirement: u64,
}

public struct SelectRequest<phantom T: key> {
  machine_id: ID,
  selection_number: u64,
  paid: u64,
  receipts: VecMap<TypeName, u64>,
}

// ============================================= Key 

public struct MembershipKey has store, copy, drop{}

public struct LayerKey<phantom LayerType: drop> has store, copy, drop{} // 이건 Membership 에

public struct ItemBagKey<phantom LayerType: drop> has store, copy, drop{} // 이건 Membership에

public struct PropertyKey<phantom PropertyType: drop> has store, drop, copy {} //이건 Item에

public struct TicketKey<phantom TicketType: drop> has store, drop, copy {}

public struct ConfigKey has store, copy, drop{} // 이건 item에

public struct ProductKey has store, copy, drop{
  selection_number: u64
}


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
public struct PropertyValue<phantom PropertyType: drop> has store {
  value: u64,
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

public fun new_vending_machine<T: key>(
    policy: &MembershipPolicy<T>,
    cap: &MembershipPolicyCap<T>,
    ctx: &mut TxContext
): (VendingMachine<T>, VendingMachineCap<T>){
    assert!(object::id(policy) == cap.policy_id, ENotOwner);

    let id = object::new(ctx);
    let machine_id = id.to_inner();

    (
      VendingMachine<T> {
        id,
        policy_id: object::id(policy),
        selections: vector<Selection>[],
        // selections: vec_map::empty<u64, Selection>(),
        size: 0,
        balance: balance::zero()
      },
      VendingMachineCap<T> { id: object::new(ctx), machine_id }
    )
}

// ===================================== Public Functions for Membership User (or Typescript SDK)

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

public fun add_ticket_to_membership<T: key, TicketType: drop>(
    membership: &mut Membership<T>,
    ticket: Ticket<TicketType>,
) {
    if (!dynamic_field::exists_(&membership.id, TicketKey<TicketType>{})){
      dynamic_field::add<TicketKey<TicketType>, vector<Ticket<TicketType>>>(&mut membership.id, TicketKey<TicketType>{}, vector<Ticket<TicketType>>[]);
    };

    let ticket_bag = dynamic_field::borrow_mut<TicketKey<TicketType>, vector<Ticket<TicketType>>>(&mut membership.id, TicketKey<TicketType>{});
    ticket_bag.push_back(ticket);
}

public fun pop_ticket_from_membership<T: key, TicketType: drop>(
    membership: &mut Membership<T>
): Ticket<TicketType> {
    let ticket_bag = dynamic_field::borrow_mut<TicketKey<TicketType>, vector<Ticket<TicketType>>>(&mut membership.id, TicketKey<TicketType>{});
    ticket_bag.pop_back()
}


public fun attatch_property_to_item<LayerType: drop, PropertyType: drop, Config: store + copy + drop>(
    item: &mut Item<LayerType>,
    property: Property<PropertyType, Config>,
) {
    dynamic_field::add(&mut item.id, PropertyKey<PropertyType>{}, property);
}

// ===================================== Membership Policy Functions for Admin Package
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
// ===================================== Create Functions for Admin Package

public fun new_item<LayerType: drop, Config: store + copy + drop>(
    _: LayerType,
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

public fun new_property_value<PropertyType: drop>(
    _: PropertyType,
    value: u64,
): PropertyValue<PropertyType> {
  PropertyValue{value}
}

public fun new_ticket<TicketType: drop>(
    _: TicketType,
    ctx: &mut TxContext,
): Ticket<TicketType> {
  Ticket<TicketType> {id: object::new(ctx)}
}

public fun add_selection_to_machine<T: key, Product>(machine: &mut VendingMachine<T>, cap: &VendingMachineCap<T>, price: u64) {
  assert!(object::id(machine) == cap.machine_id, ENotOwner);
  let selection = Selection{
    conditions: vector<Condition>[],
    price,
    product: type_name::get<Product>()
  };

  machine.selections.push_back(selection);
  machine.size = machine.selections.length();
}

public fun borrow_selection<T: key>(machine: &mut VendingMachine<T>, cap: &VendingMachineCap<T>, index: u64): &Selection {
  assert!(object::id(machine) == cap.machine_id, ENotOwner);

  machine.selections.borrow(index)
}

public fun borrow_mut_selection<T: key>(machine: &mut VendingMachine<T>, cap: &VendingMachineCap<T>, index: u64): &mut Selection {
  assert!(object::id(machine) == cap.machine_id, ENotOwner);

  machine.selections.borrow_mut(index)
}

public fun add_condition_to_selection<TicketType: drop>(selection: &mut Selection, requirement: u64) {
  selection.conditions.push_back(Condition{
    ticket_type: type_name::get<TicketType>(),
    requirement
  })
} 

public fun add_product_to_machine<T: key, Product: store>(machine: &mut VendingMachine<T>, cap: &VendingMachineCap<T>, selection_number: u64, product: Product) {
  assert!(object::id(machine) == cap.machine_id, ENotOwner);
  machine.selections.borrow(selection_number);

  if (!dynamic_field::exists_(&machine.id, ProductKey{selection_number})) {
    dynamic_field::add(&mut machine.id, ProductKey{selection_number}, vector<Product>[]);
  };

  dynamic_field::borrow_mut<ProductKey, vector<Product>>(&mut machine.id, ProductKey{selection_number})
  .push_back(product);
}

// ===================================== Public Functions
public fun has_layer<T: key, LayerType: drop>(policy: &MembershipPolicy<T>): bool {
  dynamic_field::exists_(&policy.id, LayerKey<LayerType> {})
}
public fun has_property<T: key, PropertyType: drop>(policy: &MembershipPolicy<T>): bool {
  dynamic_field::exists_(&policy.id, PropertyKey<PropertyType> {})
}

// ============================= Public Package Functions
public fun new_request<T: key>(machine: &VendingMachine<T>, selection_number: u64): SelectRequest<T> {
  SelectRequest {
    machine_id: object::id(machine),
    selection_number,
    paid: 0,
    receipts: vec_map::empty<TypeName, u64>()
  }
}

public fun add_balance_to_machine<T: key>(machine: &mut VendingMachine<T>, request: &mut SelectRequest<T>, coin: Coin<SUI> ) {
  assert!(object::id(machine) == request.machine_id, ENotCorrectVendingMachine);
  request.paid = request.paid + coin.value();
  machine.balance.join(coin.into_balance());
}

public fun burn_ticket<T: key, TicketType: drop>(
    _: TicketType,
    machine: &mut VendingMachine<T>, 
    request: &mut SelectRequest<T>, 
    ticket: Ticket<TicketType> 
  ) {
  assert!(object::id(machine) == request.machine_id, ENotCorrectVendingMachine);
  let Ticket<TicketType> {id} = ticket;
  id.delete();
  let (key, value) = request.receipts.remove(&type_name::get<TicketType>());
  request.receipts.insert(key, value+1);
}

public fun confirm_request<T: key, Product: store>(
    machine: &mut VendingMachine<T>,
    request: SelectRequest<T>,
): (ID, u64, Product) {
    let SelectRequest { machine_id, selection_number, paid, receipts } = request;

    let selection = &machine.selections[selection_number];

    assert!(selection.price == paid, ENotEnoughPaid);

    let mut completed = selection.conditions;
    let mut total = selection.conditions.length();

    while (total > 0) {
        let condition = completed.pop_back();

        let ticket_type = condition.ticket_type;
        let burned_tickets = *receipts.get(&ticket_type);
        assert!(burned_tickets == condition.requirement, EIllegalRule);

        total = total - 1;
    };

    let product = dynamic_field::borrow_mut<ProductKey, vector<Product>>(&mut machine.id, ProductKey{selection_number})
    .pop_back();

    (machine_id, paid, product)
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