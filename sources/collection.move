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

// =======================================================
// ======================== Shared Objects
// =======================================================

public struct COLLECTION has drop {}

public struct Collection has key, store {
  id: UID,
  membership_type: MembershipType,
  layer_order: VecSet<LayerType>,
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

// =======================================================
// ======================== Events
// =======================================================
public struct CollectionCreated has copy, drop {
  id: ID
}

public struct MarketCreated has copy, drop {
  collection_id: ID,
  id: ID
}

public struct MembershipCreated has copy, drop {
  collection_id: ID,
  id: ID
}

public struct ItemCreated has copy, drop {
  collection_id: ID,
  id: ID
}

public struct AttributeScrollCreated has copy, drop {
  collection_id: ID,
  id: ID
}

public struct TicketCreated has copy, drop {
  collection_id: ID,
  id: ID
}

// =======================================================
// ======================== Types : Collection Metadata
// =======================================================
public struct MembershipType has store, copy, drop {
  collection_id: ID,
  type_name: String, 
}

public struct LayerType has store, copy, drop {
  collection_id: ID,
  type_name: String, 
}

public struct ItemType has store, copy, drop {
  collection_id: ID,
  layer_type: LayerType, 
  type_name: String,
}

public struct AttributeType has store, copy, drop {
  collection_id: ID,
  type_name: String,
}

public struct TicketType has store, copy, drop {
  collection_id: ID,
  type_name: String,
}

// =======================================================
// ======================== Objects
// =======================================================
public struct Membership has key, store {
  id: UID,
  `type`: MembershipType,
  img_url: String,
}

public struct ItemSocket has store {
  layer_type: LayerType, 
  socket: Option<Item>
}

public struct Item has key, store{
  id: UID,
  `type`: ItemType, 
  img_url: String
}

public struct AttributeScroll has key, store {
  id: UID,
  attribute: Attribute
}

public struct Attribute has store {
  `type`: AttributeType, 
  value: u64
}

public struct Ticket has key, store {
  id: UID,
  `type`: TicketType, 
}

// =======================================================
// ======================== Keys
// =======================================================
public struct TypeKey<phantom Type: store + copy + drop> has store, copy, drop {
  type_name: String
}

public struct ItemBagKey has store, copy, drop {
  layer_type: LayerType
}

public struct TicketBagKey has store, copy, drop {
  ticket_type: String
}

public struct ProductKey has store, copy, drop{
  listing_number: u64
}

public struct TypeConfigKey<phantom Type: store + copy + drop> has store, copy, drop {
  type_name: String,
  name: String,
}

public struct TypeConfig has store, copy, drop {
  content: String
}


// ==================================================

fun init(otw: COLLECTION, ctx: &mut TxContext) {
  let publisher = package::claim(otw, ctx);

  let mut display = display::new<Membership>(&publisher, ctx);
  display.add(b"id".to_string(), b"{id}".to_string());
  display.add(b"name".to_string(), b"{type.name}".to_string());
  display.add(b"collection".to_string(), b"{type.collection_id}".to_string());
  // display.add(b"description".to_string(), b"{membership.description}".to_string());
  display.add(b"img_url".to_string(), b"{img_url}".to_string());
  display.update_version();

  transfer::public_transfer(display, ctx.sender());
  transfer::public_transfer(publisher, ctx.sender());
}

// =======================================================
// ======================== Entry Functions 
// =======================================================

entry fun create_collection(name: String, ctx: &mut TxContext) {
  let (col, col_cap) = new(name, ctx);
  transfer::share_object(col);
  transfer::transfer(col_cap, ctx.sender());
}

#[allow(lint(share_owned))]
entry fun create_market(collection: &Collection, cap: &CollectionCap, name: String, ctx: &mut TxContext) {
  assert!(object::id(collection) == cap.collection_id, ENotOwner);

  let (market, market_cap) = new_market(collection, cap, name, ctx);
  transfer::share_object(market);
  transfer::transfer(market_cap, ctx.sender());
}

// =======================================================
// ======================== Admin Public Functions : Mint Functions
// =======================================================
public fun mint_membership(collection: &Collection, cap: &CollectionCap, img_url: String, recipient: address, ctx: &mut TxContext) {
  assert!(object::id(collection) == cap.collection_id, ENotOwner);

  let membership = new_membership(collection, cap, img_url, ctx);
  transfer::transfer(membership, recipient);
}

public fun mint_item(collection: &mut Collection, cap: &CollectionCap, layer_type: String, item_type: String, recipient: address, ctx: &mut TxContext) { 
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);
  assert!(collection.layer_order.contains(&LayerType{collection_id, type_name: layer_type}), ENotExistType);

  // let img_url = dynamic_field::borrow<TypeConfigKey<ItemType>, TypeConfig>(&mut collection.id, TypeConfigKey<ItemType>{`type`: item_type, name: b"img_url".to_string()});

  let item = new_item(collection, cap, layer_type, item_type, ctx);
  transfer::transfer(item, recipient)
}

// off-chain Mission 에 필요한 Backend에서 사용 할 mint ticket
public fun mint_ticket(collection: &mut Collection, cap: &CollectionCap, layer_type: String, item_type: String, recipient: address, ctx: &mut TxContext) { 
  // let collection_id = object::id(collection);
  // assert!(collection_id == cap.collection_id, ENotOwner);
  // assert!(collection.layer_types.contains(&LayerType{collection_id, `type`: layer_type}), ENotExistType);

  // // let img_url = dynamic_field::borrow<TypeConfigKey<ItemType>, TypeConfig>(&mut collection.id, TypeConfigKey<ItemType>{`type`: item_type, name: b"img_url".to_string()});

  // let item = new_item(collection, cap, layer_type, item_type, ctx);
  // transfer::transfer(item, recipient)
}



// =======================================================
// ======================== Admin Public Functions : New Object Functions
// =======================================================
public fun new(name: String, ctx: &mut TxContext): (Collection, CollectionCap){
  let id = object::new(ctx);
  let collection_id = id.to_inner();
  event::emit(CollectionCreated { id: collection_id });
  let mut collection = 
    Collection { 
      id, 
      membership_type: MembershipType{collection_id, type_name: name},
      layer_order: vec_set::empty<LayerType>(),
      balance: balance::zero(),
      version: 0
    };
  dynamic_field::add(&mut collection.id, TypeKey<MembershipType> {type_name: name}, MembershipType{collection_id, type_name: name});

  (
    collection,
    CollectionCap { id: object::new(ctx), collection_id },
  )
}

public fun new_market(collection: &Collection, cap: &CollectionCap, name: String, ctx: &mut TxContext): (Market, MarketCap){
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);

  let id = object::new(ctx);
  let market_id = id.to_inner();
  event::emit(MarketCreated { collection_id, id: market_id });
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

public fun new_membership(collection: &Collection, cap: &CollectionCap, img_url: String, ctx: &mut TxContext): Membership { 
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);

  let id = object::new(ctx);
  event::emit(MembershipCreated { collection_id, id: id.to_inner() });
  Membership {
    id,
    `type`: collection.membership_type,
    img_url
  }
}

public fun new_item(collection: &mut Collection, cap: &CollectionCap, layer_type_name: String, item_type_name: String, ctx: &mut TxContext): Item { 
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);

  let layer_type = dynamic_field::borrow<TypeKey<LayerType>, LayerType>(&collection.id, TypeKey<LayerType>{type_name: layer_type_name});
  assert!(dynamic_field::exists_(&collection.id, TypeKey<ItemType> {type_name: item_type_name}));

  let id = object::new(ctx);

  let img_url_cfg = dynamic_field::borrow<TypeConfigKey<ItemType>, TypeConfig>(&collection.id, TypeConfigKey<ItemType>{type_name: item_type_name, name: b"img_url".to_string()});
  let item_img_url = img_url_cfg.content;

  let item_type = ItemType {
    collection_id,
    layer_type: *layer_type,
    type_name: item_type_name
  };

  event::emit(ItemCreated { collection_id, id: id.to_inner() });

  Item {
    id,
    `type`: item_type,
    img_url: item_img_url
  }
}

public fun new_attribute_scroll(collection: &Collection, cap: &CollectionCap, type_name: String, value: u64, ctx: &mut TxContext): AttributeScroll { 
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);

  let attribute_type = dynamic_field::borrow<TypeKey<AttributeType>, AttributeType>(&collection.id, TypeKey<AttributeType>{type_name});
  let attribute = Attribute {`type`: *attribute_type, value};

  let id = object::new(ctx);
  event::emit(AttributeScrollCreated { collection_id, id: id.to_inner() });
  AttributeScroll {
    id,
    attribute
  }
}

public fun new_ticket(collection: &Collection, cap: &CollectionCap, type_name: String, ctx: &mut TxContext): Ticket { 
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);

  let ticket_type = dynamic_field::borrow<TypeKey<TicketType>, TicketType>(&collection.id, TypeKey<TicketType>{type_name});
  let id = object::new(ctx);
  event::emit(TicketCreated { collection_id, id: id.to_inner() });
  Ticket {
    id,
    `type`: *ticket_type
  }
}

// =======================================================
// ======================== Admin Public Functions : Register Type Functions
// =======================================================

public fun register_layer_type(collection: &mut Collection, cap: &CollectionCap, type_name: String) {
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);

  collection.layer_order.insert(LayerType{collection_id, type_name});
  dynamic_field::add(&mut collection.id, TypeKey<LayerType> {type_name}, LayerType{collection_id, type_name});
  collection.update_version();
}

public fun register_item_type(collection: &mut Collection, cap: &CollectionCap, layer_type_name: String, item_type_name: String, img_url: String) {
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);
  assert!(dynamic_field::exists_(&collection.id, TypeKey<LayerType>{type_name: layer_type_name}));

  let layer_type = dynamic_field::borrow<TypeKey<LayerType>, LayerType>(&collection.id, TypeKey<LayerType>{type_name: layer_type_name});
  dynamic_field::add(&mut collection.id, TypeKey<ItemType> {type_name: item_type_name}, ItemType{collection_id, layer_type: *layer_type, type_name: item_type_name});

  register_type_config<ItemType>(collection, cap, item_type_name, b"img_url".to_string(), img_url);
  collection.update_version();
}

public fun register_attribute_type(collection: &mut Collection, cap: &CollectionCap, type_name: String) {
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);

  dynamic_field::add(&mut collection.id, TypeKey<AttributeType> {type_name}, AttributeType{collection_id, type_name});
  collection.update_version();
}

public fun register_ticket_type(collection: &mut Collection, cap: &CollectionCap,type_name: String) {
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);

  dynamic_field::add(&mut collection.id, TypeKey<TicketType> {type_name}, TicketType{collection_id, type_name});
  collection.update_version();
}

public fun register_type_config<Type: store + copy + drop>(collection: &mut Collection, cap: &CollectionCap, type_name: String, name: String, content: String) {
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);
  assert!(dynamic_field::exists_(&collection.id, TypeKey<Type>{type_name}), ENotExistType);
  
  dynamic_field::add(&mut collection.id, TypeConfigKey<Type>{type_name, name}, TypeConfig{content});
  collection.update_version();
}

// =======================================================
// ======================== Admin Public Functions : Update Type Functions
// =======================================================

/// 여기 first_index, index_to_go 를 파라미터로 받는게 좋겠다.
public fun update_layer_order(collection: &mut Collection, cap: &CollectionCap, i: u64, j: u64) {
    let collection_id = object::id(collection);
    assert!(collection_id == cap.collection_id, ENotOwner);

    let mut lt = collection.layer_order.into_keys();
    lt.swap(i, j);

    collection.layer_order = vec_set::from_keys(lt);

    collection.update_version();
}

public fun update_type_config<Type: store + copy + drop>(collection: &mut Collection, cap: &CollectionCap, type_name: String, name: String, content: String) {
  let collection_id = object::id(collection);
  assert!(collection_id == cap.collection_id, ENotOwner);

  assert!(dynamic_field::exists_(&collection.id, TypeKey<Type>{type_name}), ENotExistType);
  let config = dynamic_field::borrow_mut<TypeConfigKey<Type>, TypeConfig>(&mut collection.id, TypeConfigKey<Type>{type_name, name});
  config.content = content;
}

// =======================================================
// ======================== Admin Public Functions : Market Functions
// =======================================================
public fun register_listing_to_market<Product: key + store>(
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

public fun register_purchase_condition_to_listing(
  collection: &Collection,
  market: &mut Market,
  cap: &MarketCap,
  listing_number: u64,
  ticket_type: String,
  requirement: u64
  ) {
    let listing = borrow_mut_listing(collection, market, cap, listing_number);

    listing.conditions.push_back(PurchaseCondition{
      ticket_type: TicketType{collection_id: object::id(collection), type_name: ticket_type},
      requirement
    })
} 

public fun stock_product_to_listing<Product: key + store>(
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

// =======================================================
// ======================== User Public Functions: Item Functions
// =======================================================

public fun equip_item_to_membership(collection: &Collection, membership: &mut Membership, item: Item){
  assert!(object::id(collection) == membership.`type`.collection_id, EInvalidCollection);

  let item_type = item.`type`;
  assert!(dynamic_field::exists_(&collection.id, TypeKey<LayerType>{type_name: item_type.layer_type.type_name}));

  // item이 갖고 있는 LayerType의 ItemSocket이 없을 경우 추가해줌
  if (!dynamic_field::exists_<TypeKey<LayerType>>(&membership.id, TypeKey<LayerType>{type_name: item_type.layer_type.type_name})){
    dynamic_field::add(&mut membership.id, TypeKey<LayerType>{type_name: item_type.layer_type.type_name}, ItemSocket{layer_type: item_type.layer_type, socket: option::none<Item>()});
  };

  // Membership에 ItemBag 없으면 추가해 줌
  if (!dynamic_field::exists_<ItemBagKey>(&membership.id, ItemBagKey{layer_type: item_type.layer_type})){
    dynamic_field::add(&mut membership.id, ItemBagKey{layer_type: item_type.layer_type}, vector<Item>[]);
  };

  let item_socket = dynamic_field::borrow_mut<TypeKey<LayerType>, ItemSocket>(&mut membership.id, TypeKey<LayerType>{type_name: item_type.layer_type.type_name});
  if (item_socket.socket.is_none()) {
    item_socket.socket.fill(item);
    return
  }; 
  
  let old_item = item_socket.socket.swap(item);
  insert_item_into_bag(membership, item_type.layer_type.type_name, old_item);
}

public fun insert_item_into_bag(membership: &mut Membership, layer_type_name: String, item: Item){
  let layer_type = LayerType {collection_id: membership.`type`.collection_id, type_name: layer_type_name};
  dynamic_field::borrow_mut<ItemBagKey, vector<Item>>(&mut membership.id, ItemBagKey{layer_type})
  .push_back(item);
}

public fun pop_latest_item_from_bag(membership: &mut Membership, layer_type_name: String): Item{
  let layer_type = LayerType {collection_id: membership.`type`.collection_id, type_name: layer_type_name};
  dynamic_field::borrow_mut<ItemBagKey, vector<Item>>(&mut membership.id, ItemBagKey{layer_type})
  .pop_back()
}

public fun attach_attribute_to_item(collection: &Collection, item: &mut Item, attribute_scroll: AttributeScroll) {
  assert!(object::id(collection) == item.`type`.collection_id, EInvalidCollection);

  let AttributeScroll {id, attribute} = attribute_scroll;
  id.delete();
  dynamic_field::add(&mut item.id, TypeKey<AttributeType>{type_name: attribute.`type`.type_name}, attribute)
}

// =======================================================
// ======================== User Public Functions: Ticket Functions
// =======================================================

// Ticket 오브젝트 되면서 없애도 되나?
public fun insert_ticket_into_bag(
    collection: &Collection,
    membership: &mut Membership,
    ticket: Ticket,
) {
    assert!(object::id(collection) == ticket.`type`.collection_id, EInvalidCollection);

    if (!dynamic_field::exists_(&membership.id, TicketBagKey{ticket_type: ticket.`type`.type_name})){
      dynamic_field::add<TicketBagKey, vector<Ticket>>(&mut membership.id, TicketBagKey{ticket_type: ticket.`type`.type_name}, vector<Ticket>[]);
    };

    let ticket_bag = dynamic_field::borrow_mut<TicketBagKey, vector<Ticket>>(&mut membership.id, TicketBagKey{ticket_type: ticket.`type`.type_name});
    ticket_bag.push_back(ticket);
}

// Ticket 오브젝트 되면서 없애도 되나?
public fun pop_latest_ticket_from_bag(membership: &mut Membership, `type`: String): Ticket {
    let ticket_bag = dynamic_field::borrow_mut<TicketBagKey, vector<Ticket>>(&mut membership.id, TicketBagKey{ticket_type: `type`});
    ticket_bag.pop_back()
}


// =======================================================
// ======================== User Public Functions: Purchase Functions
// =======================================================
public fun new_purchase_request(
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

public fun consume_ticket(
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


public fun confirm_purchase_request<Product: key + store>(
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

// =======================================================
// ======================== Admin Public Functions : Borrow Functions
// =======================================================
public (package) fun borrow_listing(
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

public (package) fun borrow_mut_listing(
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


// =======================================================
// ============================= Public Package Functions
// =======================================================

public (package) fun update_version(collection: &mut Collection) {
  collection.version = collection.version + 1;
}