module exclusuive::collection;

use std::string::{String};

use sui::vec_map::{Self, VecMap};
use sui::balance::{Self, Balance};
use sui::sui::{SUI};
use sui::dynamic_field;
use sui::display::{Self};
use sui::package;

const ENotOwner: u64 = 1;
const EInvalidCollection: u64 = 2;
const ENotItemExist: u64 = 3;
const ENotPropertyExist: u64 = 4;
const EInvalidPropertyValue: u64 = 5;

public struct COLLECTION has drop {}

public struct Collection has key {
  id: UID,
  base_type: BaseType,
  layer_types: VecMap<AddTypeKey<LayerType>, LayerType>,
  item_types: VecMap<AddTypeKey<ItemType>, ItemType>,
  property_types: VecMap<AddTypeKey<PropertyType>, PropertyType>,
  // rules: VecSet<Rule>,
  balance: Balance<SUI>,
}

// Owned
public struct CollectionCap has key, store {
  id: UID,
  collection_id: ID
}

// Collection Metadata 
// -----------------------------------------------
public struct BaseType has store, copy, drop {
  collection_id: ID,
  name: String, 
}

public struct LayerType has store, copy, drop {
  collection_id: ID,
  `type`: String, 
  order: u64
}

public struct ItemType has store, copy, drop {
  collection_id: ID,
  layer_type: LayerType,
  `type`: String, 
  img_url: String
}

public struct PropertyType has store, copy, drop {
  collection_id: ID,
  `type`: String,
  min: u64,
  max: u64,
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
  img_url: String
}

public struct Layer has store {
  `type`: LayerType, 
  socket: Option<Item>
}

public struct Item has key, store{
  id: UID,
  `type`: ItemType, 
  properties: VecMap<AddTypeKey<PropertyType>, Property>,
}

public struct Property has store {
  `type`: PropertyType, 
  value: u64
}

// public struct Rule has store, copy, drop {
//   name: String,
//   description: String,
//   config: RuleConfig
// }

// public struct RuleConfig has store, copy, drop {
//   config: u64,
// }

// ==================================================
public struct AddTypeKey<phantom Type: store + copy + drop> has store, copy, drop {
  `type`: String
}

public struct StoreKey<Type: store + copy + drop> has store, copy, drop {
  `type`: Type
}

public struct ItemBagKey has store, copy, drop {
  item_id: ID
}

public struct ConfigKey<phantom Type: store + copy + drop> has store, copy, drop {
  name: String
}

// ==================================================

fun init(otw: COLLECTION, ctx: &mut TxContext) {
  let publisher = package::claim(otw, ctx);

  let mut display = display::new<Base>(&publisher, ctx);
  display.add(b"id".to_string(), b"{id}".to_string());
  display.add(b"name".to_string(), b"{name}".to_string());
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
public fun update_layer_type_to_base(collection: &Collection, base: &mut Base) {
  collection.layer_types.keys().do_ref!(|key| {
    let layer_type = collection.layer_types.get(key);
    if (!dynamic_field::exists_(&base.id, StoreKey<LayerType>{`type`: *layer_type})){
      base.add_layer_to_base(*layer_type);
    };
  });
}

public fun equip_item_to_base(collection: &Collection, base: &mut Base, item: Item){
  assert!(object::id(collection) == base.`type`.collection_id, EInvalidCollection);
  let layer_type = item.`type`.layer_type;
  let layer = dynamic_field::borrow_mut<StoreKey<LayerType>, Layer>(&mut base.id, StoreKey<LayerType>{`type`: layer_type});

  if (layer.socket.is_none()) {
    layer.socket.fill(item);
    return
  }; 
  
  let old_item = layer.socket.swap(item);
  dynamic_field::borrow_mut<ItemBagKey, vector<Item>>(&mut base.id, ItemBagKey{item_id: object::id(&old_item)}).push_back(old_item);
}

public fun remove_item_from_bag(base: &mut Base, item_id: ID): Item{
  dynamic_field::remove(&mut base.id, ItemBagKey{item_id})
}

public fun add_property_to_item(collection: &Collection, item: &mut Item, property: Property) {
  assert!(collection.item_types.contains(&AddTypeKey{`type`: item.`type`.`type` }), ENotItemExist);
  assert!(collection.property_types.contains(&AddTypeKey{`type`: property.`type`.`type` }), ENotPropertyExist);

  item.properties.insert(
    AddTypeKey{`type`: property.`type`.`type`},
    property
  );
}

// 조건에 맞게 달성하면 item 또는 property를 얻을 수 있음
// public fun request_property(collection: &Collection, base: &Base): Property { }

// public fun request_item(collection: &Collection, base: &Base): Item { }

// ======================== Admin Public Functions 

public fun new_base(collection: &Collection, cap: &CollectionCap, img_url: String, ctx: &mut TxContext): Base { 
  assert!(object::id(collection) == cap.collection_id, ENotOwner);
  let mut base = Base {
    id: object::new(ctx),
    `type`: collection.base_type,
    img_url
  };

  collection.layer_types.keys().do_ref!(|key| {
    let layer_type = collection.layer_types.get(key);
    base.add_layer_to_base(*layer_type);
  } );

  base
}

public fun new_item(collection: &Collection, cap: &CollectionCap, `type`: String, ctx: &mut TxContext): Item { 
  assert!(object::id(collection) == cap.collection_id, ENotOwner);
  let item_type = collection.item_types.get<AddTypeKey<ItemType>, ItemType>(&AddTypeKey<ItemType>{`type`});
  Item {
    id: object::new(ctx),
    `type`: *item_type,      
    properties: vec_map::empty<AddTypeKey<PropertyType>, Property>()
  }
}

public fun new_property(collection: &Collection, cap: &CollectionCap, `type`: String, value: u64): Property { 
  assert!(object::id(collection) == cap.collection_id, ENotOwner);

  let property_type = collection.property_types.get(&AddTypeKey<PropertyType>{`type`});
  assert!(property_type.min <= value && value <= property_type.max, EInvalidPropertyValue);

  Property {`type`: *property_type, value}
}

public fun store_property(collection: &mut Collection, cap: &CollectionCap, property: Property) {
    let collection_id = object::id(collection);
    assert!(collection_id == cap.collection_id, ENotOwner);

    if (!dynamic_field::exists_(&collection.id, StoreKey<PropertyType>{`type`: property.`type`})) {

    dynamic_field::add<StoreKey<PropertyType>, vector<Property>>(&mut collection.id, StoreKey<PropertyType>{`type`: property.`type`}, vector::empty<Property>());
    };
    let property_vec = dynamic_field::borrow_mut<StoreKey<PropertyType>, vector<Property>>(&mut collection.id, StoreKey<PropertyType>{`type`: property.`type`});
    property_vec.push_back(property);
}

public fun add_layer_type( collection: &mut Collection, cap: &CollectionCap, `type`: String, order: u64) {
    let collection_id = object::id(collection);
    assert!(collection_id == cap.collection_id, ENotOwner);

    collection.layer_types.insert(
      AddTypeKey{`type`}, 
      LayerType{collection_id, `type`, order}
    );
}

public fun add_item_type( collection: &mut Collection, cap: &CollectionCap, layer_type: String, `type`: String, img_url: String) {
    let collection_id = object::id(collection);
    assert!(collection_id == cap.collection_id, ENotOwner);

    let layer_type = collection.layer_types.get<AddTypeKey<LayerType>, LayerType>(
      &AddTypeKey{`type`:layer_type});

    collection.item_types.insert(
      AddTypeKey{`type`}, 
      ItemType{collection_id, layer_type: *layer_type, `type`, img_url}
    );
}

public fun add_property_type(collection: &mut Collection, cap: &CollectionCap, `type`: String, min: u64, max: u64) {
    let collection_id = object::id(collection);
    assert!(collection_id == cap.collection_id, ENotOwner);

    collection.property_types.insert(
      AddTypeKey{`type`}, 
      PropertyType{collection_id, `type`, min, max }
    );
}

public fun add_config_to_type<Type: store + copy + drop>(collection: &mut Collection, cap: &CollectionCap, name: String, content: String) {
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);

  dynamic_field::add(&mut collection.id, ConfigKey<Type>{name}, Config{name, content});
}

// ======================== Private Functions 

fun new(name: String, ctx: &mut TxContext): (Collection, CollectionCap){
  let id = object::new(ctx);
  let collection_id = id.to_inner();
  // event::emit(CollectionPolicyCreated<T> { id: policy_id });
  (
      Collection { 
        id, 
        base_type: BaseType{ collection_id, name },
        layer_types: vec_map::empty<AddTypeKey<LayerType>, LayerType>(),
        item_types: vec_map::empty<AddTypeKey<ItemType>, ItemType>(),
        property_types: vec_map::empty<AddTypeKey<PropertyType>, PropertyType>(),
        // rules: vec_set::empty<Rule>(), 
        balance: balance::zero() 
      },
      CollectionCap { id: object::new(ctx), collection_id },
  )
}

fun add_layer_to_base(base: &mut Base, layer_type: LayerType){
  let layer = Layer {
    `type`: layer_type,
    socket: option::none<Item>()
  };
  dynamic_field::add<StoreKey<LayerType>, Layer>(&mut base.id, StoreKey<LayerType>{`type`: layer_type}, layer);
}