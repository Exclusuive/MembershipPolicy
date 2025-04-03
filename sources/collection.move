module exclusuive::collection;

use std::string::{String};

use sui::sui::{SUI};
use sui::balance::{Self, Balance};
use sui::dynamic_field;
use sui::vec_set::{Self, VecSet};
use sui::display::{Self};
use sui::package;

const ENotOwner: u64 = 1;
const EInvalidCollection: u64 = 2;
const ENotExistType: u64 = 3;

public struct COLLECTION has drop {}

public struct Collection has key, store {
  id: UID,
  base_type: BaseType,
  layer_types: VecSet<LayerType>,
  property_types: VecSet<PropertyType>,
  ticket_types: VecSet<TicketType>,
  balance: Balance<SUI>,
  version: u64,
}

public struct CollectionCap has key, store {
  id: UID,
  collection_id: ID
}

public struct Supplyer<Product: store> has key, store {
  id: UID,
  collection_id: ID,
  selections: vector<Selection<Product>>,
  size: u64,
  balance: Balance<SUI>,
}

public struct Selection<Product: store> has store {
  number: u64,
  conditions: vector<Condition>,
  price: u64,
  product: Product
}

public struct Condition has store, copy, drop {
  ticket_type: TicketType,
  requirement: u64,
}

public struct SupplyerCap has key, store {
  id: UID,
  machine_id: ID
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

public struct ConfigKey<phantom Type: store + copy + drop> has store, copy, drop {
  `type`: String
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

entry fun mint_and_tranfer_base(collection: &Collection, cap: &CollectionCap, img_url: String, recipient: address, ctx: &mut TxContext) {
  assert!(object::id(collection) == cap.collection_id, ENotOwner);

  let base = new_base(collection, cap, img_url, ctx);
  transfer::transfer(base, recipient);
}

// ======================== User Public Functions
public fun equip_item_to_base(collection: &Collection, base: &mut Base, item: Item){
  assert!(object::id(collection) == base.`type`.collection_id, EInvalidCollection);

  let layer_type = item.`type`;
  if (!dynamic_field::exists_<TypeKey<LayerType>>(&base.id, TypeKey<LayerType>{`type`: layer_type.`type`})){
    dynamic_field::add(&mut base.id, TypeKey<LayerType>{`type`: layer_type.`type`}, ItemSocket{`type`: layer_type, socket: option::none<Item>()});
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

public fun new_item(collection: &Collection, cap: &CollectionCap, layer_type: String, item_type: String, img_url: String, ctx: &mut TxContext): Item { 
  assert!(object::id(collection) == cap.collection_id, ENotOwner);
  let layer_type = dynamic_field::borrow<TypeKey<LayerType>, LayerType>(&collection.id, TypeKey<LayerType>{`type`: layer_type});
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
    dynamic_field::add(&mut collection.id, TypeKey<PropertyType> {`type`}, PropertyType{collection_id, `type`});
    collection.update_version();
}

public fun add_config_to_type<Type: store + copy + drop>(collection: &mut Collection, cap: &CollectionCap, `type`: String, name: String, content: String) {
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);

  assert!(dynamic_field::exists_(&collection.id, TypeKey<Type>{`type`}), ENotExistType);
  dynamic_field::add(&mut collection.id, ConfigKey<Type>{`type`}, Config{name, content});
}

// ======================== Private Functions 

fun new(name: String, ctx: &mut TxContext): (Collection, CollectionCap){
  let id = object::new(ctx);
  let collection_id = id.to_inner();
  // event::emit(CollectionPolicyCreated<T> { id: policy_id });
  (
      Collection { 
        id, 
        base_type: BaseType{collection_id, `type`: name},
        layer_types: vec_set::empty<LayerType>(),
        property_types: vec_set::empty<PropertyType>(),
        ticket_types: vec_set::empty<TicketType>(),
        balance: balance::zero(),
        version: 0
      },
      CollectionCap { id: object::new(ctx), collection_id },
  )
}

public (package) fun update_version(collection: &mut Collection) {
  collection.version = collection.version + 1;
}