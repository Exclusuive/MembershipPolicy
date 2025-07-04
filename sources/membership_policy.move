module exclusuive::membership_policy;

use std::type_name::{Self, TypeName};
use std::string::{String};

use sui::package::{Self, Publisher};
use sui::balance::{Self, Balance};
use sui::coin::{Coin};
use sui::sui::{SUI};
use sui::dynamic_field;
use sui::vec_map::{Self, VecMap};
use sui::vec_set::{Self, VecSet};
use sui::event;

const ENotOwner: u64 = 100;
const ERuleAlreadySet: u64 = 101;
const ENotHasLayer: u64 = 102;
const ENotCorrectMembershipPolicy: u64 = 104;
const EIllegalRule: u64 = 105;
const ENotCorrectMarket: u64 = 106;
const ENotEnoughPaid: u64 = 107;


// =======================================================
// ======================== Shared Objects
// =======================================================
public struct MembershipPolicy<phantom T: key> has key, store {
  id: UID,
  balance: Balance<SUI>,
  layer_order: VecSet<TypeName>,
  version: u16,
}

public struct MembershipPolicyCap<phantom T: key> has key, store {
  id: UID,
  policy_id: ID
}

public struct Market<phantom T: key> has key, store {
  id: UID,
  policy_id: ID,
  listings: vector<Listing>,
  balance: Balance<SUI>,
}

public struct MarketCap<phantom T: key> has key, store {
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
  ticket_type: TypeName,
  requirement: u64,
}

public struct PurchaseRequest<phantom T: key> {
  market_id: ID,
  listing_number: u64,
  paid: u64,
  receipts: VecMap<TypeName, u64>,
}

// =======================================================
// ======================== Events
// =======================================================
public struct MembershipPolicyCreated<phantom T: key> has copy, drop {
  id: ID
}

public struct MarketCreated<phantom T: key> has copy, drop {
  id: ID
}

public struct MembershipCreated<phantom T: key> has copy, drop {
  id: ID
}

public struct ItemCreated<phantom T: key> has copy, drop {
  id: ID
}

public struct TicketCreated<phantom T: key> has copy, drop {
  id: ID
}

// =======================================================
// ======================== Objects
// =======================================================
public struct Membership<phantom T: key> has key, store {
  id: UID,
  policy_id: ID
}

public struct ItemSocket<phantom LayerType: drop> has store {
  socket: Option<Item<LayerType>>,
}

public struct Item<phantom LayerType: drop> has key, store {
  id: UID,
  item_type: String,
  img_url: String,
}

public struct AttributeScroll<phantom AttributeType: drop> has key, store {
  id: UID,
  attribute: Attribute<AttributeType>
}

public struct Attribute<phantom AttributeType: drop> has store {
  value: u64,
}

public struct Ticket<phantom TicketType: drop> has key, store {
  id: UID,
}

// =======================================================
// ======================== Keys
// =======================================================

// MembershiPolicy
public struct MembershipKey has store, copy, drop{}

// Membership
public struct RegisterTypeKey<phantom Type: drop> has store, copy, drop{}

// public struct LayerKey<phantom LayerType: drop> has store, copy, drop{}

public struct ItemKey<phantom LayerType: drop> has store, copy, drop {
  item_type: String
}
// public struct AttributeKey<phantom AttributeType: drop> has store, drop, copy {} 

// public struct TicketKey<phantom TicketType: drop> has store, drop, copy {} 

// Bag
public struct ItemBagKey<phantom LayerType: drop> has store, copy, drop{} 

public struct TicketBagKey<phantom TicketType: drop> has store, drop, copy {}

// // Types
// public struct TypeConfigKey has store, copy, drop{}

// Market
public struct ProductKey has store, copy, drop{
  listing_number: u64
}

// =======================================================
// ======================== Public Functions For Membership Admin Package : New Functions
// =======================================================
public fun new<T: key>(pub: &Publisher, ctx: &mut TxContext): (MembershipPolicy<T>, MembershipPolicyCap<T>){
  assert!(package::from_package<T>(pub), 0);

  let id = object::new(ctx);
  let policy_id = id.to_inner();

  event::emit(MembershipPolicyCreated<T> { id: policy_id });
  (
      MembershipPolicy<T> { 
        id, 
        balance: balance::zero(),
        layer_order: vec_set::empty<TypeName>(),
        version: 0,
        },
      MembershipPolicyCap<T> { id: object::new(ctx), policy_id },
  )
}

public fun new_market<T: key>(
  policy: &MembershipPolicy<T>,
  cap: &MembershipPolicyCap<T>,
  ctx: &mut TxContext
): (Market<T>, MarketCap<T>){
    assert!(object::id(policy) == cap.policy_id, ENotOwner);

    let id = object::new(ctx);
    let market_id = id.to_inner();

    event::emit(MarketCreated<T> { id: market_id });
    (
      Market<T> {
        id,
        policy_id: object::id(policy),
        listings: vector<Listing>[],
        balance: balance::zero()
      },
      MarketCap<T> { id: object::new(ctx), market_id }
    )
}

public fun new_membership<T: key, OTW: drop>(
  _: OTW,
  policy: &MembershipPolicy<T>,
  ctx: &mut TxContext,
): Membership<T> {
    let membership = Membership<T>{id: object::new(ctx), policy_id: object::id(policy)};
    event::emit(MembershipCreated<T> { id: object::id(&membership) });
    membership
}


public fun new_item<T: key, LayerType: drop>(
  _: LayerType,
  item_type: String,
  img_url: String,
  ctx: &mut TxContext,
): Item<LayerType> {
    let item = Item<LayerType> {
      id: object::new(ctx),
      item_type,
      img_url,
    };

    let item_id = object::id(&item);
    event::emit(ItemCreated<T> { id: item_id });

    item
}

public fun new_attribute_scroll<AttributeType: drop>(
  _: AttributeType, 
  value: u64, 
  ctx: &mut TxContext
): AttributeScroll<AttributeType> {
  let attribute = Attribute{value};

  AttributeScroll {
    id: object::new(ctx),
    attribute
  }
}

public fun new_ticket<T:key, TicketType: drop>(
  _: TicketType,
  ctx: &mut TxContext,
): Ticket<TicketType> {
    let ticket = Ticket<TicketType> {id: object::new(ctx)};

    let ticket_id = object::id(&ticket);
    event::emit(TicketCreated<T> { id: ticket_id });

    ticket
}


// =======================================================
// ======================== Public Functions For Membership Admin Package : Membership Functions
// =======================================================
public fun attach_membership<T: key>(
    self: &mut UID,
    policy: &MembershipPolicy<T>,
    membership: Membership<T>,
){
  assert!(object::id(policy) == membership.policy_id, ENotCorrectMembershipPolicy);
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

// =======================================================
// ======================== Public Functions For Membership Admin Package : Item Functions
// =======================================================
public fun equip_item_to_membership<T: key, LayerType: drop>(
    membership: &mut Membership<T>,
    // self: &mut UID,
    item: Item<LayerType>,
    policy: &MembershipPolicy<T>,
) {
    assert!(has_layer<T, LayerType>(policy), ENotHasLayer);

    if (!dynamic_field::exists_(&membership.id, ItemBagKey<LayerType>{})){
      dynamic_field::add(&mut membership.id, ItemBagKey<LayerType>{}, vector<Item<LayerType>>[]);
    };

    if (!dynamic_field::exists_(&membership.id, RegisterTypeKey<LayerType>{})){
      let item_socket = ItemSocket<LayerType>{
        socket: option::none(), 
      };
      dynamic_field::add(&mut membership.id, RegisterTypeKey<LayerType>{}, item_socket);
    };

    let mut item_socket = dynamic_field::remove<RegisterTypeKey<LayerType>, ItemSocket<LayerType>>(&mut membership.id, RegisterTypeKey<LayerType>{});

    if (item_socket.socket.is_some()) {
      let old_item = item_socket.socket.extract();
      insert_item_into_bag(membership, old_item);
    };

    item_socket.socket.fill(item);
    dynamic_field::add(&mut membership.id, RegisterTypeKey<LayerType>{}, item_socket);
}

public fun insert_item_into_bag<T: key, LayerType: drop>(
    membership: &mut Membership<T>,
    item: Item<LayerType>,
  ){
    let item_bag = dynamic_field::borrow_mut<ItemBagKey<LayerType>, vector<Item<LayerType>>>(&mut membership.id, ItemBagKey{});
    item_bag.push_back(item);
}

public fun pop_latest_item_from_bag<T: key, LayerType: drop>(
    membership: &mut Membership<T>,
  ): Item<LayerType>{
    let item_bag = dynamic_field::borrow_mut<ItemBagKey<LayerType>, vector<Item<LayerType>>>(&mut membership.id, ItemBagKey{});
    item_bag.pop_back()
}

public fun attatch_attribute_to_item<LayerType: drop, AttributeType: drop>(
    item: &mut Item<LayerType>,
    attribute_scroll: AttributeScroll<AttributeType>
) {
    let AttributeScroll {id, attribute} = attribute_scroll;
    id.delete();
    dynamic_field::add(&mut item.id, RegisterTypeKey<AttributeType>{}, attribute);
}


// =======================================================
// ======================== Public Functions For Membership Admin Package : Ticket Functions
// =======================================================
public fun store_ticket_to_ticket_bag<T: key, TicketType: drop>(
    membership: &mut Membership<T>,
    ticket: Ticket<TicketType>,
) {
    if (!dynamic_field::exists_(&membership.id, TicketBagKey<TicketType>{})){
      dynamic_field::add<TicketBagKey<TicketType>, vector<Ticket<TicketType>>>(&mut membership.id, TicketBagKey<TicketType>{}, vector<Ticket<TicketType>>[]);
    };

    let ticket_bag = dynamic_field::borrow_mut<TicketBagKey<TicketType>, vector<Ticket<TicketType>>>(&mut membership.id, TicketBagKey<TicketType>{});
    ticket_bag.push_back(ticket);
}

public fun retrieve_ticket_from_ticket_bag<T: key, TicketType: drop>(
    membership: &mut Membership<T>
): Ticket<TicketType> {
    let ticket_bag = dynamic_field::borrow_mut<TicketBagKey<TicketType>, vector<Ticket<TicketType>>>(&mut membership.id, TicketBagKey<TicketType>{});
    ticket_bag.pop_back()
}

// =======================================================
// ======================== Public Functions For Membership Admin Package : Register Type Functions
// =======================================================
public fun register_layer_type<T: key, LayerType: drop, Config: store + copy + drop>(
    _: LayerType,
    policy: &mut MembershipPolicy<T>,
    cap: &MembershipPolicyCap<T>,
    cfg: Config,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_layer<T, LayerType>(policy), ERuleAlreadySet);

    let layer_type = type_name::get<LayerType>();
    policy.layer_order.insert(layer_type);
    dynamic_field::add(&mut policy.id, RegisterTypeKey<LayerType> {}, cfg);
    policy.update_version_policy();
}

public fun register_item_type<T: key, LayerType: drop, Config: store + copy + drop>(
    _: LayerType,
    policy: &mut MembershipPolicy<T>,
    cap: &MembershipPolicyCap<T>,
    item_type: String,
    cfg: Config,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(has_layer<T, LayerType>(policy), ENotHasLayer);

    dynamic_field::add(&mut policy.id, ItemKey<LayerType> {item_type}, cfg);
    policy.update_version_policy();
}

public fun register_attribute_type<T: key, AttributeType: drop, Config: store + copy + drop>(
    _: AttributeType,
    policy: &mut MembershipPolicy<T>,
    cap: &MembershipPolicyCap<T>,
    cfg: Config,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_attribute<T, AttributeType>(policy), ERuleAlreadySet);

    dynamic_field::add(&mut policy.id, RegisterTypeKey<AttributeType> {}, cfg);
    policy.update_version_policy();
}

public fun register_ticket_type<T: key, TicketType: drop, Config: store + copy + drop>(
    _: TicketType,
    policy: &mut MembershipPolicy<T>,
    cap: &MembershipPolicyCap<T>,
    cfg: Config,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_ticket<T, TicketType>(policy), ERuleAlreadySet);

    dynamic_field::add(&mut policy.id, RegisterTypeKey<TicketType> {}, cfg);
    policy.update_version_policy();
}

// =======================================================
// ======================== Public Functions For Membership Admin Package : Market Functions
// =======================================================
public fun register_listing_to_market<T: key, Product: store>(market: &mut Market<T>, cap: &MarketCap<T>, price: u64) {
  assert!(object::id(market) == cap.market_id, ENotOwner);
  let listing = Listing{
    number: market.listings.length(),
    conditions: vector<PurchaseCondition>[],
    price,
    product: type_name::get<Product>()
  };

  dynamic_field::add(&mut market.id, ProductKey{listing_number: market.listings.length()}, vector<Product>[]);

  market.listings.push_back(listing);
}

public fun register_purchase_condition_to_listing<TicketType: drop>(listing: &mut Listing, requirement: u64) {
  listing.conditions.push_back(PurchaseCondition{
    ticket_type: type_name::get<TicketType>(),
    requirement
  })
} 

public fun stock_product_to_listing<T: key, Product: store>(market: &mut Market<T>, cap: &MarketCap<T>, listing_number: u64, product: Product) {
  assert!(object::id(market) == cap.market_id, ENotOwner);
  market.listings.borrow(listing_number);

  dynamic_field::borrow_mut<ProductKey, vector<Product>>(&mut market.id, ProductKey{listing_number})
  .push_back(product);
}

public fun borrow_listing<T: key>(market: &Market<T>, cap: &MarketCap<T>, index: u64): &Listing {
  assert!(object::id(market) == cap.market_id, ENotOwner);
  market.listings.borrow(index)
}

public fun borrow_mut_listing<T: key>(market: &mut Market<T>, cap: &MarketCap<T>, index: u64): &mut Listing {
  assert!(object::id(market) == cap.market_id, ENotOwner);
  market.listings.borrow_mut(index)
}

// =======================================================
// ======================== User Public Functions : Purchase Functions
// =======================================================
public fun new_purchase_request<T: key>(market: &Market<T>, listing_number: u64): PurchaseRequest<T> {
  PurchaseRequest {
    market_id: object::id(market),
    listing_number,
    paid: 0,
    receipts: vec_map::empty<TypeName, u64>()
  }
}

public fun consume_ticket<T: key, TicketType: drop>(
    _: TicketType,
    market: &Market<T>, 
    request: &mut PurchaseRequest<T>, 
    ticket: Ticket<TicketType> 
  ) {
  assert!(object::id(market) == request.market_id, ENotCorrectMarket);
  let Ticket<TicketType> {id} = ticket;
  id.delete();
  let (key, value) = request.receipts.remove(&type_name::get<TicketType>());
  request.receipts.insert(key, value+1);
}

public fun add_balance_to_market<T: key>(market: &mut Market<T>, request: &mut PurchaseRequest<T>, coin: Coin<SUI> ) {
  assert!(object::id(market) == request.market_id, ENotCorrectMarket);
  request.paid = request.paid + coin.value();
  market.balance.join(coin.into_balance());
}

public fun confirm_purchase_request<T: key, Product: store>(
    market: &mut Market<T>,
    request: PurchaseRequest<T>,
): (ID, u64, Product) {
    let PurchaseRequest { market_id, listing_number, paid, receipts } = request;

    let listing = &market.listings[listing_number];

    assert!(listing.price == paid, ENotEnoughPaid);

    let mut completed = listing.conditions;
    let mut total = listing.conditions.length();

    while (total > 0) {
        let condition = completed.pop_back();

        let ticket_type = condition.ticket_type;
        let burned_tickets = *receipts.get(&ticket_type);
        assert!(burned_tickets == condition.requirement, EIllegalRule);

        total = total - 1;
    };

    let product = dynamic_field::borrow_mut<ProductKey, vector<Product>>(&mut market.id, ProductKey{listing_number})
    .pop_back();

    (market_id, paid, product)
}

// ===================================== Public Functions
public fun has_layer<T: key, LayerType: drop>(policy: &MembershipPolicy<T>): bool {
  dynamic_field::exists_(&policy.id, RegisterTypeKey<LayerType> {})
}
public fun has_attribute<T: key, AttributeType: drop>(policy: &MembershipPolicy<T>): bool {
  dynamic_field::exists_(&policy.id, RegisterTypeKey<AttributeType> {})
}
public fun has_ticket<T: key, TicketType: drop>(policy: &MembershipPolicy<T>): bool {
  dynamic_field::exists_(&policy.id, RegisterTypeKey<TicketType> {})
}

public fun update_version_policy<T: key>(policy: &mut MembershipPolicy<T>) {
  policy.version = policy.version + 1;
}

public fun policy_id<T: key>(cap: &MembershipPolicyCap<T>): ID {
  cap.policy_id
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