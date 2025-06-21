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

// #[test_only]
// use std::debug;

// use sui::transfer_policy;

const ENotOwner: u64 = 1;
const EInvalidCollection: u64 = 2;
const EInvalidMarket: u64 = 3;
const ENotExistType: u64 = 4;
const ENotEnoughPaid: u64 = 5;
const EIllegalRule: u64 = 6;

public struct COLLECTION has drop {}

public struct Collection has key, store {
  id: UID,
  chracter_type: CharacterType,
  layer_types: VecSet<LayerType>,
  attribute_types: VecSet<AttributeType>,
  ticket_types: VecSet<TicketType>,
  item_types: VecSet<ItemType>,
  balance: Balance<SUI>,
  version: u64,
}

public struct CollectionCap has key, store {
  id: UID,
  collection_id: ID
}

public struct Market has key, store {
  id: UID,
  collection_id: ID,
  name: String,
  listings: vector<Listing>,
  balance: Balance<SUI>,
}

public struct MarketCap has key, store {
  id: UID,
  market_id: ID
}

public struct Listing has store {
  number: u64,
  conditions: vector<PurchaseCondition>,
  price: u64,
  product: TypeName
}

public struct PurchaseCondition has store, copy, drop {
  ticket_type: TicketType,
  requirement: u64,
}

public struct PurchaseRequest {
  market_id: ID,
  listing_number: u64,
  paid: u64,
  receipts: VecMap<TicketType, u64>,
}

// Collection Event 
// -----------------------------------------------
public struct CollectionCreated has copy, drop {
  id: ID
}

public struct MarketCreated has copy, drop {
  id: ID
}

public struct CharacterCreated has copy, drop {
  id: ID
}

public struct ItemCreated has copy, drop {
  id: ID
}

public struct TicketCreated has copy, drop {
  id: ID
}
// Collection Metadata 
// -----------------------------------------------
public struct CharacterType has store, copy, drop {
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
}

public struct AttributeType has store, copy, drop {
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
public struct Character has key, store {
  id: UID,
  `type`: CharacterType,
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

public struct Attribute has store {
  `type`: AttributeType, 
  value: u64
}

public struct AttributeScroll has key, store {
  id: UID,
  attribute: Attribute
}

public struct Ticket has key, store {
  id: UID,
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
  listing_number: u64
}

public struct ConfigKey<phantom Type: store + copy + drop> has store, copy, drop {
  `type`: String,
  name: String,
}

// ==================================================

fun init(otw: COLLECTION, ctx: &mut TxContext) {
  let publisher = package::claim(otw, ctx);

  let mut display = display::new<Character>(&publisher, ctx);
  display.add(b"id".to_string(), b"{id}".to_string());
  display.add(b"name".to_string(), b"{type.name}".to_string());
  display.add(b"collection".to_string(), b"{type.collection_id}".to_string());
  // display.add(b"description".to_string(), b"{chracter.description}".to_string());
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
entry fun create_market(collection: &Collection, cap: &CollectionCap, name: String, ctx: &mut TxContext) {
  assert!(object::id(collection) == cap.collection_id, ENotOwner);

  let (market, market_cap) = new_market(collection, name, ctx);
  transfer::share_object(market);
  transfer::transfer(market_cap, ctx.sender());
}

entry fun mint_and_tranfer_chracter(collection: &Collection, cap: &CollectionCap, img_url: String, recipient: address, ctx: &mut TxContext) {
  assert!(object::id(collection) == cap.collection_id, ENotOwner);

  let chracter = new_chracter(collection, cap, img_url, ctx);
  transfer::transfer(chracter, recipient);
}

entry fun mint_item(collection: &mut Collection, cap: &CollectionCap, layer_type: String, item_type: String, recipient: address, ctx: &mut TxContext) { 
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);
  assert!(collection.layer_types.contains(&LayerType{collection_id, `type`: layer_type}), ENotExistType);

  // let img_url = dynamic_field::borrow<ConfigKey<ItemType>, Config>(&mut collection.id, ConfigKey<ItemType>{`type`: item_type, name: b"img_url".to_string()});

  let item = new_item(collection, cap, layer_type, item_type, ctx);
  transfer::transfer(item, recipient)
}

// ======================== User Public Functions
public fun equip_item_to_chracter(collection: &Collection, chracter: &mut Character, item: Item){
  assert!(object::id(collection) == chracter.`type`.collection_id, EInvalidCollection);

  let layer_type = item.`type`;
  if (!dynamic_field::exists_<TypeKey<LayerType>>(&chracter.id, TypeKey<LayerType>{`type`: layer_type.`type`})){
    dynamic_field::add(&mut chracter.id, TypeKey<LayerType>{`type`: layer_type.`type`}, ItemSocket{`type`: layer_type, socket: option::none<Item>()});
  };

  if (!dynamic_field::exists_<ItemBagKey>(&chracter.id, ItemBagKey{`type`: layer_type.`type`})){
    dynamic_field::add(&mut chracter.id, ItemBagKey{`type`: layer_type.`type`}, vector<Item>[]);
  };

  let layer = dynamic_field::borrow_mut<TypeKey<LayerType>, ItemSocket>(&mut chracter.id, TypeKey<LayerType>{`type`: layer_type.`type`});

  if (layer.socket.is_none()) {
    layer.socket.fill(item);
    return
  }; 
  
  let old_item = layer.socket.swap(item);
  dynamic_field::borrow_mut<ItemBagKey, vector<Item>>(&mut chracter.id, ItemBagKey{`type`: layer_type.`type`})
  .push_back(old_item);
}

public fun pop_item_from_bag(chracter: &mut Character, `type`: String): Item{
  dynamic_field::borrow_mut<ItemBagKey, vector<Item>>(&mut chracter.id, ItemBagKey{`type`})
  .pop_back()
}

public fun attach_attribute_to_item(collection: &Collection, item: &mut Item, attribute_scroll: AttributeScroll) {
  assert!(object::id(collection) == item.`type`.collection_id, EInvalidCollection);

  let AttributeScroll {id, attribute} = attribute_scroll;
  id.delete();
  dynamic_field::add(&mut item.id, TypeKey<AttributeType>{`type`: attribute.`type`.`type`}, attribute)
}

// Ticket 오브젝트 되면서 없애도 되나?
public fun add_ticket_to_chracter(
    collection: &Collection,
    chracter: &mut Character,
    ticket: Ticket,
) {
    assert!(object::id(collection) == ticket.`type`.collection_id, EInvalidCollection);

    if (!dynamic_field::exists_(&chracter.id, TicketBagKey{`type`: ticket.`type`.`type`})){
      dynamic_field::add<TicketBagKey, vector<Ticket>>(&mut chracter.id, TicketBagKey{`type`: ticket.`type`.`type`}, vector<Ticket>[]);
    };

    let ticket_bag = dynamic_field::borrow_mut<TicketBagKey, vector<Ticket>>(&mut chracter.id, TicketBagKey{`type`: ticket.`type`.`type`});
    ticket_bag.push_back(ticket);
}

// Ticket 오브젝트 되면서 없애도 되나?
public fun pop_ticket_from_chracter(chracter: &mut Character, `type`: String): Ticket {
    let ticket_bag = dynamic_field::borrow_mut<TicketBagKey, vector<Ticket>>(&mut chracter.id, TicketBagKey{`type`});
    ticket_bag.pop_back()
}


// ======================== Admin Public Functions 
public fun new(name: String, ctx: &mut TxContext): (Collection, CollectionCap){
  let id = object::new(ctx);
  let collection_id = id.to_inner();
  event::emit(CollectionCreated { id: collection_id });
  let mut collection = 
    Collection { 
      id, 
      chracter_type: CharacterType{collection_id, `type`: name},
      layer_types: vec_set::empty<LayerType>(),
      attribute_types: vec_set::empty<AttributeType>(),
      ticket_types: vec_set::empty<TicketType>(),
      item_types: vec_set::empty<ItemType>(),
      balance: balance::zero(),
      version: 0
    };

  dynamic_field::add(&mut collection.id, TypeKey<CharacterType> {`type`: name}, CharacterType{collection_id, `type`: name});

  (
    collection,
    CollectionCap { id: object::new(ctx), collection_id },
  )
}
public fun new_chracter(collection: &Collection, cap: &CollectionCap, img_url: String, ctx: &mut TxContext): Character { 
  assert!(object::id(collection) == cap.collection_id, ENotOwner);
  let chracter = Character {
    id: object::new(ctx),
    `type`: collection.chracter_type,
    img_url
  };

  chracter
}

// public fun new_item(collection: &mut Collection, cap: &CollectionCap, layer_type: String, item_type: String, img_url: String, ctx: &mut TxContext): Item { 
public fun new_item(collection: &mut Collection, cap: &CollectionCap, layer_type: String, item_type: String, ctx: &mut TxContext): Item { 
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);

  let layer_type = dynamic_field::borrow<TypeKey<LayerType>, LayerType>(&collection.id, TypeKey<LayerType>{`type`: layer_type});
  assert!(collection.item_types.contains(&ItemType{collection_id, `type`: *layer_type, item_type}), 100);

  let item_id = object::new(ctx);
  event::emit(ItemCreated { id: item_id.to_inner() });

  let img_url_cfg = dynamic_field::borrow<ConfigKey<ItemType>, Config>(&collection.id, ConfigKey<ItemType>{`type`: item_type, name: b"img_url".to_string()});

  Item {
    id: item_id,
    `type`: *layer_type,      
    item_type,
    img_url: img_url_cfg.content
  }
}

public fun new_attribute_scroll(collection: &Collection, cap: &CollectionCap, `type`: String, value: u64, ctx: &mut TxContext): AttributeScroll { 
  assert!(object::id(collection) == cap.collection_id, ENotOwner);

  let attribute_type = dynamic_field::borrow<TypeKey<AttributeType>, AttributeType>(&collection.id, TypeKey<AttributeType>{`type`});
  let attribute = Attribute {`type`: *attribute_type, value};
  AttributeScroll {
    id: object::new(ctx),
    attribute
  }
}

public fun new_ticket(collection: &Collection, cap: &CollectionCap, `type`: String, ctx: &mut TxContext): Ticket { 
  assert!(object::id(collection) == cap.collection_id, ENotOwner);

  let ticket_type = dynamic_field::borrow<TypeKey<TicketType>, TicketType>(&collection.id, TypeKey<TicketType>{`type`});
  Ticket {
    id: object::new(ctx),
    `type`: *ticket_type
  }
}


public fun add_layer_type(collection: &mut Collection, cap: &CollectionCap, `type`: String) {
    let collection_id = object::id(collection);
    assert!(collection_id == cap.collection_id, ENotOwner);

    collection.layer_types.insert(LayerType{collection_id, `type`});
    dynamic_field::add(&mut collection.id, TypeKey<LayerType> {`type`}, LayerType{collection_id, `type`});
    collection.update_version();
}

public fun add_item_type(collection: &mut Collection, cap: &CollectionCap, layer_type: String, item_type: String, img_url: String) {
    let collection_id = object::id(collection);
    assert!(collection_id == cap.collection_id, ENotOwner);
    assert!(collection.layer_types.contains(&LayerType{collection_id, `type`: layer_type}), ENotExistType);

    let layer_type = dynamic_field::borrow<TypeKey<LayerType>, LayerType>(&collection.id, TypeKey<LayerType>{`type`: layer_type});
    collection.item_types.insert(ItemType{collection_id, `type`: *layer_type, item_type});
        dynamic_field::add(&mut collection.id, TypeKey<ItemType> {`type`: item_type}, ItemType{collection_id, `type`: *layer_type, item_type});

    add_config_to_type<ItemType>(collection, cap, item_type, b"img_url".to_string(), img_url);

    collection.update_version();
}

public fun add_attribute_type(collection: &mut Collection, cap: &CollectionCap, `type`: String) {
    let collection_id = object::id(collection);
    assert!(collection_id == cap.collection_id, ENotOwner);

    collection.attribute_types.insert(AttributeType{collection_id, `type`});
    dynamic_field::add(&mut collection.id, TypeKey<AttributeType> {`type`}, AttributeType{collection_id, `type`});
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

/// 여기 first_index, index_to_go 를 파라미터로 받는게 좋겠다.
public fun update_layer_order(collection: &mut Collection, cap: &CollectionCap, i: u64, j: u64) {
    let collection_id = object::id(collection);
    assert!(collection_id == cap.collection_id, ENotOwner);

    let mut lt = collection.layer_types.into_keys();
    lt.swap(i, j);

    collection.layer_types = vec_set::from_keys(lt);

    collection.update_version();
}

public fun add_listing_to_market<Product: key + store>(
  collection: &Collection,
  market: &mut Market,
  cap: &MarketCap,
  price: u64
  ) {
    let collection_id = object::id(collection);
    assert!(collection_id == market.collection_id, EInvalidCollection);
    assert!(object::id(market) == cap.market_id, ENotOwner);

  let listing = Listing{
    number: market.listings.length(),
    conditions: vector<PurchaseCondition>[],
    price,
    product: type_name::get<Product>()
  };

  let key = ProductKey{listing_number: listing.number};
  dynamic_field::add(&mut market.id, key, vector<Product>[]);

  market.listings.push_back(listing);
}

public fun add_product_to_market<Product: key + store>(
  collection: &Collection,
  market: &mut Market,
  cap: &MarketCap,
  listing_number: u64, 
  product: Product
  ) {
    let collection_id = object::id(collection);
    assert!(collection_id == market.collection_id, EInvalidCollection);
    assert!(object::id(market) == cap.market_id, ENotOwner);

    market.listings.borrow(listing_number);

    let key = ProductKey{listing_number};
    dynamic_field::borrow_mut<ProductKey, vector<Product>>(&mut market.id, key)
    .push_back(product);
}

public fun borrow_listing(
  collection: &Collection,
  market: &Market,
  cap: &MarketCap,
  index: u64
  ): &Listing {
    let collection_id = object::id(collection);
    assert!(collection_id == market.collection_id, EInvalidCollection);
    assert!(object::id(market) == cap.market_id, ENotOwner);

    market.listings.borrow(index)
}

public fun borrow_mut_listing(
  collection: &Collection,
  market: &mut Market,
  cap: &MarketCap,
  index: u64
  ): &mut Listing {
    let collection_id = object::id(collection);
    assert!(collection_id == market.collection_id, EInvalidCollection);
    assert!(object::id(market) == cap.market_id, ENotOwner);

    market.listings.borrow_mut(index)
}

public fun add_condition_to_listing(
  collection: &Collection,
  market: &mut Market,
  cap: &MarketCap,
  listing_number: u64,
  ticket_type: String,
  requirement: u64
  ) {
    let listing = borrow_mut_listing(collection, market, cap, listing_number);

    listing.conditions.push_back(PurchaseCondition{
      ticket_type: TicketType{collection_id: object::id(collection), `type`: ticket_type},
      requirement
    })
} 

// ============================= Request Functions
public fun new_request(
  collection: &Collection,
  market: &mut Market,
  listing_number: u64
  ): PurchaseRequest {
    assert!(object::id(collection) == market.collection_id, EInvalidCollection);
    PurchaseRequest {
      market_id: object::id(market),
      listing_number,
      paid: 0,
      receipts: vec_map::empty<TicketType, u64>()
    }
}

public fun burn_ticket(
    collection: &Collection,
    market: &Market,
    request: &mut PurchaseRequest, 
    ticket: Ticket 
  ) {
    assert!(object::id(collection) == market.collection_id, EInvalidCollection);
    assert!(object::id(market) == request.market_id, EInvalidMarket);

    let Ticket {id, `type`} = ticket;
    id.delete();

    if (!request.receipts.contains(&`type`)) {
      request.receipts.insert(`type`, 0 as u64)
    };
    let (key, value) = request.receipts.remove(&`type`);
    request.receipts.insert(key, value + 1);
}

public fun add_balance_to_market(
  collection: &Collection,
  market: &mut Market,
  request: &mut PurchaseRequest, 
  coin: Coin<SUI> ) {
    let collection_id = object::id(collection);
    assert!(collection_id == market.collection_id, EInvalidCollection);

    request.paid = request.paid + coin.value();
    market.balance.join(coin.into_balance());
}


public fun confirm_request<Product: key + store>(
    collection: &Collection,
    market: &mut Market,
    request: PurchaseRequest, 
): Product {
    assert!(object::id(collection) == market.collection_id, EInvalidCollection);

    assert!(object::id(market) == request.market_id, EInvalidMarket);
    let PurchaseRequest { market_id: _, listing_number, paid, receipts } = request;

    let listing = &market.listings[listing_number];
    assert!(listing.price == paid, ENotEnoughPaid);

    let mut completed = listing.conditions;
    let mut total = listing.conditions.length();

    while (total > 0) {
      let condition = completed.pop_back();
      let burned_tickets = *receipts.get<TicketType, u64>(&condition.ticket_type);
      assert!(burned_tickets == condition.requirement, EIllegalRule);

      total = total - 1;
  };

    let key = ProductKey{listing_number};
    let product_vec = dynamic_field::borrow_mut<ProductKey, vector<Product>>(&mut market.id, key);
    let product = product_vec.pop_back();
    product
}

// ============================= Public Package Functions

public (package) fun new_market(collection: &Collection, name: String, ctx: &mut TxContext): (Market, MarketCap){
  let id = object::new(ctx);
  let market_id = id.to_inner();
  event::emit(MarketCreated { id: market_id });
  (
    Market{
      id,
      collection_id: object::id(collection),
      name,
      listings: vector<Listing>[],
      balance: balance::zero(),
    },
    MarketCap { id: object::new(ctx), market_id },
  )
}

public (package) fun update_version(collection: &mut Collection) {
  collection.version = collection.version + 1;
}