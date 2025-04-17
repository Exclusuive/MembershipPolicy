module exclusuive::collection;

use std::string::{String};
use std::type_name::{Self, TypeName};

use sui::coin::{Coin};
use sui::sui::{SUI};
use sui::balance::{Self, Balance};
use sui::dynamic_field;
use sui::vec_set::{Self, VecSet};
use sui::vec_map::{Self, VecMap};
use sui::display::{Self};
use sui::package;
use sui::event;

const ENotOwner: u64 = 1;
const EInvalidCollection: u64 = 2;
const EInvalidSupplier: u64 = 3;
const ENotExistType: u64 = 4;
const ENotEnoughPaid: u64 = 5;
const EIllegalRule: u64 = 6;

public struct COLLECTION has drop {}

public struct Collection has key, store {
  id: UID,
  base_type: BaseType,
  layer_types: VecSet<LayerType>,
  property_types: VecSet<PropertyType>,
  ticket_types: VecSet<TicketType>,
  item_types: VecSet<ItemType>,
  balance: Balance<SUI>,
  version: u64,
}

public struct CollectionCap has key, store {
  id: UID,
  collection_id: ID
}

public struct Supplier has key, store {
  id: UID,
  collection_id: ID,
  name: String,
  selections: vector<Selection>,
  size: u64,
  balance: Balance<SUI>,
}

public struct SupplierCap has key, store {
  id: UID,
  supplier_id: ID
}

public struct Selection has store {
  number: u64,
  conditions: vector<Condition>,
  price: u64,
  product: TypeName
}

public struct Condition has store, copy, drop {
  ticket_type: TicketType,
  requirement: u64,
}

public struct SelectRequest {
  supplier_id: ID,
  selection_number: u64,
  paid: u64,
  receipts: VecMap<TicketType, u64>,
}

// Collection Event 
// -----------------------------------------------
public struct CollectionCreated has copy, drop {
  id: ID
}

public struct SupplierCreated has copy, drop {
  id: ID
}
// Collection Metadata 
// -----------------------------------------------
public struct BaseType has store, copy, drop {
  collection_id: ID,
  `type`: String, 
}

public struct LayerType has store, copy, drop {
  collection_id: ID,
  `type`: String, 
}

public struct ItemType has store, copy, drop {
  collection_id: ID,
  `type`: LayerType, 
  item_type: String,
  img_url: String
}

public struct PropertyType has store, copy, drop {
  collection_id: ID,
  `type`: String,
}

public struct TicketType has store, copy, drop {
  collection_id: ID,
  `type`: String,
}

public struct Config has store, copy, drop {
  name: String,
  content: String
}

// Object Struct 
// -----------------------------------------------
public struct Base has key, store {
  id: UID,
  `type`: BaseType,
  img_url: String,
}

public struct ItemSocket has store {
  `type`: LayerType, 
  socket: Option<Item>
}

public struct Item has key, store{
  id: UID,
  `type`: LayerType, 
  item_type: String,
  img_url: String
}

public struct Property has store {
  `type`: PropertyType, 
  value: u64
}

public struct Ticket has store {
  `type`: TicketType, 
}

// ==================================================
public struct TypeKey<phantom Type: store + copy + drop> has store, copy, drop {
  `type`: String
}

public struct ItemBagKey has store, copy, drop {
  `type`: String
}

public struct TicketBagKey has store, copy, drop {
  `type`: String
}

public struct ProductKey has store, copy, drop{
  selection_number: u64
}

public struct ConfigKey<phantom Type: store + copy + drop> has store, copy, drop {
  `type`: String,
  name: String,
}

// ==================================================

fun init(otw: COLLECTION, ctx: &mut TxContext) {
  let publisher = package::claim(otw, ctx);

  let mut display = display::new<Base>(&publisher, ctx);
  display.add(b"id".to_string(), b"{id}".to_string());
  display.add(b"name".to_string(), b"{type.name}".to_string());
  display.add(b"collection".to_string(), b"{type.collection_id}".to_string());
  // display.add(b"description".to_string(), b"{base.description}".to_string());
  display.add(b"img_url".to_string(), b"{img_url}".to_string());
  display.update_version();

  transfer::public_transfer(display, ctx.sender());
  transfer::public_transfer(publisher, ctx.sender());
}
// ======================== Entry Functions 

entry fun default(name: String, ctx: &mut TxContext) {
  let (col, col_cap) = new(name, ctx);
  transfer::share_object(col);
  transfer::transfer(col_cap, ctx.sender());
}

#[allow(lint(share_owned))]
entry fun create_supplier(collection: &Collection, cap: &CollectionCap, name: String, ctx: &mut TxContext) {
  assert!(object::id(collection) == cap.collection_id, ENotOwner);

  let (supplier, supplier_cap) = new_supplier(collection, name, ctx);
  transfer::share_object(supplier);
  transfer::transfer(supplier_cap, ctx.sender());
}

entry fun mint_and_tranfer_base(collection: &Collection, cap: &CollectionCap, img_url: String, recipient: address, ctx: &mut TxContext) {
  assert!(object::id(collection) == cap.collection_id, ENotOwner);

  let base = new_base(collection, cap, img_url, ctx);
  transfer::transfer(base, recipient);
}

entry fun mint_item(collection: &mut Collection, cap: &CollectionCap, layer_type: String, item_type: String, img_url: String, recipient: address, ctx: &mut TxContext) { 
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);
  assert!(collection.layer_types.contains(&LayerType{collection_id, `type`: layer_type}), ENotExistType);

  let item = new_item(collection, cap, layer_type, item_type, img_url, ctx);
  transfer::transfer(item, recipient)
}

// ======================== User Public Functions
public fun equip_item_to_base(collection: &Collection, base: &mut Base, item: Item){
  assert!(object::id(collection) == base.`type`.collection_id, EInvalidCollection);

  let layer_type = item.`type`;
  if (!dynamic_field::exists_<TypeKey<LayerType>>(&base.id, TypeKey<LayerType>{`type`: layer_type.`type`})){
    dynamic_field::add(&mut base.id, TypeKey<LayerType>{`type`: layer_type.`type`}, ItemSocket{`type`: layer_type, socket: option::none<Item>()});
  };

  if (!dynamic_field::exists_<ItemBagKey>(&base.id, ItemBagKey{`type`: layer_type.`type`})){
    dynamic_field::add(&mut base.id, ItemBagKey{`type`: layer_type.`type`}, vector<Item>[]);
  };

  let layer = dynamic_field::borrow_mut<TypeKey<LayerType>, ItemSocket>(&mut base.id, TypeKey<LayerType>{`type`: layer_type.`type`});

  if (layer.socket.is_none()) {
    layer.socket.fill(item);
    return
  }; 
  
  let old_item = layer.socket.swap(item);
  dynamic_field::borrow_mut<ItemBagKey, vector<Item>>(&mut base.id, ItemBagKey{`type`: layer_type.`type`})
  .push_back(old_item);
}

public fun pop_item_from_bag(base: &mut Base, `type`: String): Item{
  dynamic_field::borrow_mut<ItemBagKey, vector<Item>>(&mut base.id, ItemBagKey{`type`})
  .pop_back()
}

public fun attach_property_to_item(collection: &Collection, item: &mut Item, property: Property) {
  assert!(object::id(collection) == item.`type`.collection_id, EInvalidCollection);

  dynamic_field::add(&mut item.id, TypeKey<PropertyType>{`type`: property.`type`.`type`}, property)
}

public fun add_ticket_to_base(
    collection: &Collection,
    base: &mut Base,
    ticket: Ticket,
) {
    assert!(object::id(collection) == ticket.`type`.collection_id, EInvalidCollection);

    if (!dynamic_field::exists_(&base.id, TicketBagKey{`type`: ticket.`type`.`type`})){
      dynamic_field::add<TicketBagKey, vector<Ticket>>(&mut base.id, TicketBagKey{`type`: ticket.`type`.`type`}, vector<Ticket>[]);
    };

    let ticket_bag = dynamic_field::borrow_mut<TicketBagKey, vector<Ticket>>(&mut base.id, TicketBagKey{`type`: ticket.`type`.`type`});
    ticket_bag.push_back(ticket);
}

public fun pop_ticket_from_membership( base: &mut Base, `type`: String): Ticket {
    let ticket_bag = dynamic_field::borrow_mut<TicketBagKey, vector<Ticket>>(&mut base.id, TicketBagKey{`type`});
    ticket_bag.pop_back()
}


// ======================== Admin Public Functions 
public fun new_base(collection: &Collection, cap: &CollectionCap, img_url: String, ctx: &mut TxContext): Base { 
  assert!(object::id(collection) == cap.collection_id, ENotOwner);
  let base = Base {
    id: object::new(ctx),
    `type`: collection.base_type,
    img_url
  };

  base
}

public fun new_item(collection: &mut Collection, cap: &CollectionCap, layer_type: String, item_type: String, img_url: String, ctx: &mut TxContext): Item { 
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);
  let layer_type = dynamic_field::borrow<TypeKey<LayerType>, LayerType>(&collection.id, TypeKey<LayerType>{`type`: layer_type});

  if(!collection.item_types.contains(&ItemType{collection_id, `type`: *layer_type, item_type, img_url})) {
    collection.item_types.insert(ItemType{collection_id, `type`: *layer_type, item_type, img_url});
  };

  Item {
    id: object::new(ctx),
    `type`: *layer_type,      
    item_type,
    img_url
  }
}

public fun new_property(collection: &Collection, cap: &CollectionCap, `type`: String, value: u64): Property { 
  assert!(object::id(collection) == cap.collection_id, ENotOwner);

  let property_type = dynamic_field::borrow<TypeKey<PropertyType>, PropertyType>(&collection.id, TypeKey<PropertyType>{`type`});
  Property {`type`: *property_type, value}
}

public fun new_ticket(collection: &Collection, cap: &CollectionCap, `type`: String): Ticket { 
  assert!(object::id(collection) == cap.collection_id, ENotOwner);

  let ticket_type = dynamic_field::borrow<TypeKey<TicketType>, TicketType>(&collection.id, TypeKey<TicketType>{`type`});
  Ticket {`type`: *ticket_type}
}


public fun add_layer_type(collection: &mut Collection, cap: &CollectionCap, `type`: String) {
    let collection_id = object::id(collection);
    assert!(collection_id == cap.collection_id, ENotOwner);

    collection.layer_types.insert(LayerType{collection_id, `type`});
    dynamic_field::add(&mut collection.id, TypeKey<LayerType> {`type`}, LayerType{collection_id, `type`});
    collection.update_version();
}

public fun add_property_type(collection: &mut Collection, cap: &CollectionCap, `type`: String) {
    let collection_id = object::id(collection);
    assert!(collection_id == cap.collection_id, ENotOwner);

    collection.property_types.insert(PropertyType{collection_id, `type`});
    dynamic_field::add(&mut collection.id, TypeKey<PropertyType> {`type`}, PropertyType{collection_id, `type`});
    collection.update_version();
}

public fun add_ticket_type(collection: &mut Collection, cap: &CollectionCap, `type`: String) {
    let collection_id = object::id(collection);
    assert!(collection_id == cap.collection_id, ENotOwner);

    collection.ticket_types.insert(TicketType{collection_id, `type`});
    dynamic_field::add(&mut collection.id, TypeKey<TicketType> {`type`}, TicketType{collection_id, `type`});
    collection.update_version();
}

public fun add_config_to_type<Type: store + copy + drop>(collection: &mut Collection, cap: &CollectionCap, `type`: String, name: String, content: String) {
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);

  assert!(dynamic_field::exists_(&collection.id, TypeKey<Type>{`type`}), ENotExistType);
  dynamic_field::add(&mut collection.id, ConfigKey<Type>{`type`, name}, Config{name, content});
}

public fun update_config_to_type<Type: store + copy + drop>(collection: &mut Collection, cap: &CollectionCap, `type`: String, name: String, content: String) {
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);

  assert!(dynamic_field::exists_(&collection.id, TypeKey<Type>{`type`}), ENotExistType);
  let config = dynamic_field::borrow_mut<ConfigKey<Type>, Config>(&mut collection.id, ConfigKey<Type>{`type`, name});
  config.content = content;
}

public fun update_layer_order(collection: &mut Collection, cap: &CollectionCap, i: u64, j: u64) {
    let collection_id = object::id(collection);
    assert!(collection_id == cap.collection_id, ENotOwner);

    let mut lt = collection.layer_types.into_keys();
    lt.swap(i, j);

    collection.layer_types = vec_set::from_keys(lt);

    collection.update_version();
}

public fun add_selection_to_supplier<Product: store>(
  collection: &Collection,
  supplier: &mut Supplier,
  cap: &SupplierCap,
  price: u64
  ) {
    let collection_id = object::id(collection);
    assert!(collection_id == supplier.collection_id, EInvalidCollection);
    assert!(object::id(supplier) == cap.supplier_id, ENotOwner);

  let selection = Selection{
    number: supplier.selections.length(),
    conditions: vector<Condition>[],
    price,
    product: type_name::get<Product>()
  };

  dynamic_field::add(&mut supplier.id, ProductKey{selection_number: selection.number}, vector<Product>[]);

  supplier.selections.push_back(selection);
  supplier.size = supplier.selections.length();
}

public fun add_product_to_supplier<Product: store>(
  collection: &Collection,
  supplier: &mut Supplier,
  cap: &SupplierCap,
  selection_number: u64, 
  product: Product
  ) {
    let collection_id = object::id(collection);
    assert!(collection_id == supplier.collection_id, EInvalidCollection);
    assert!(object::id(supplier) == cap.supplier_id, ENotOwner);

    supplier.selections.borrow(selection_number);

    dynamic_field::borrow_mut<ProductKey, vector<Product>>(&mut supplier.id, ProductKey{selection_number})
    .push_back(product);
}

public fun add_balance_to_supplier(
  collection: &Collection,
  supplier: &mut Supplier,
  cap: &SupplierCap,
  request: &mut SelectRequest, 
  coin: Coin<SUI> ) {
    let collection_id = object::id(collection);
    assert!(collection_id == supplier.collection_id, EInvalidCollection);
    assert!(object::id(supplier) == cap.supplier_id, ENotOwner);

    request.paid = request.paid + coin.value();
    supplier.balance.join(coin.into_balance());
}

public fun borrow_selection(
  collection: &Collection,
  supplier: &Supplier,
  cap: &SupplierCap,
  index: u64
  ): &Selection {
    let collection_id = object::id(collection);
    assert!(collection_id == supplier.collection_id, EInvalidCollection);
    assert!(object::id(supplier) == cap.supplier_id, ENotOwner);

    supplier.selections.borrow(index)
}

public fun borrow_mut_selection(
  collection: &Collection,
  supplier: &mut Supplier,
  cap: &SupplierCap,
  index: u64
  ): &mut Selection {
    let collection_id = object::id(collection);
    assert!(collection_id == supplier.collection_id, EInvalidCollection);
    assert!(object::id(supplier) == cap.supplier_id, ENotOwner);

    supplier.selections.borrow_mut(index)
}

public fun add_condition_to_selection(
  collection: &Collection,
  supplier: &mut Supplier,
  cap: &SupplierCap,
  index: u64,
  ticket_type: String,
  requirement: u64
  ) {
    let selection = borrow_mut_selection(collection, supplier, cap, index);

    selection.conditions.push_back(Condition{
      ticket_type: TicketType{collection_id: object::id(collection), `type`: ticket_type},
      requirement
    })
} 

// ============================= Public Package Functions
public fun new_request(
  collection: &Collection,
  supplier: &mut Supplier,
  selection_number: u64
  ): SelectRequest {
    assert!(object::id(collection) == supplier.collection_id, EInvalidCollection);
    SelectRequest {
      supplier_id: object::id(supplier),
      selection_number,
      paid: 0,
      receipts: vec_map::empty<TicketType, u64>()
    }
}

public fun burn_ticket(
    collection: &Collection,
    supplier: &Supplier,
    request: &mut SelectRequest, 
    ticket: Ticket 
  ) {
    assert!(object::id(collection) == supplier.collection_id, EInvalidCollection);
    assert!(object::id(supplier) == request.supplier_id, EInvalidSupplier);

    let Ticket {`type`} = ticket;
    let (key, value) = request.receipts.remove(&`type`);
    request.receipts.insert(key, value+1);
}

public fun confirm_request<Product: store>(
    collection: &Collection,
    supplier: &mut Supplier,
    request: SelectRequest, 
): (ID, u64, Product) {
    assert!(object::id(collection) == supplier.collection_id, EInvalidCollection);
    assert!(object::id(supplier) == request.supplier_id, EInvalidSupplier);

    let SelectRequest { supplier_id, selection_number, paid, receipts } = request;
    let selection = &supplier.selections[selection_number];

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

    let product = dynamic_field::borrow_mut<ProductKey, vector<Product>>(&mut supplier.id, ProductKey{selection_number})
    .pop_back();

    (supplier_id, paid, product)
}

// ======================== Private Functions 

fun new(name: String, ctx: &mut TxContext): (Collection, CollectionCap){
  let id = object::new(ctx);
  let collection_id = id.to_inner();
  event::emit(CollectionCreated { id: collection_id });
  let mut collection = 
    Collection { 
      id, 
      base_type: BaseType{collection_id, `type`: name},
      layer_types: vec_set::empty<LayerType>(),
      property_types: vec_set::empty<PropertyType>(),
      ticket_types: vec_set::empty<TicketType>(),
      item_types: vec_set::empty<ItemType>(),
      balance: balance::zero(),
      version: 0
    };

  dynamic_field::add(&mut collection.id, TypeKey<BaseType> {`type`: name}, BaseType{collection_id, `type`: name});

  (
    collection,
    CollectionCap { id: object::new(ctx), collection_id },
  )
}

fun new_supplier(collection: &Collection, name: String, ctx: &mut TxContext): (Supplier, SupplierCap){
  let id = object::new(ctx);
  let supplier_id = id.to_inner();
  event::emit(SupplierCreated { id: supplier_id });
  (
    Supplier{
      id,
      collection_id: object::id(collection),
      name,
      selections: vector<Selection>[],
      size: 0,
      balance: balance::zero(),
    },
    SupplierCap { id: object::new(ctx), supplier_id },
  )
}

public (package) fun update_version(collection: &mut Collection) {
  collection.version = collection.version + 1;
}