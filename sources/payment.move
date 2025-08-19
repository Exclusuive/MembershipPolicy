module exclusuive::payment;

use exclusuive::community::{Community};
use exclusuive::membership::{Membership};
use exclusuive::item::{Item};
use std::string::{Self, String};
use sui::balance::{Self, Balance};
use sui::sui::SUI;
use sui::coin::Coin;

public struct Market has key, store {
  id: UID,
  community_id: ID,
  listings: vector<Listing>,
  balance: Balance<SUI>,
}

public struct MarketCap has key, store {
  id: UID,
  market_id: ID
}

public struct Listing has store {
  number: u64,
  price: u64,
  item: Item
}

public fun list(
    community: &Community,
    market: &mut Market,
    cap: &MarketCap,
    item: Item,
    price: u64
) {
    let community_id = object::id(community);
    assert!(community_id == market.community_id);
    let market_id = object::id(market);
    assert!(market_id == cap.market_id);

    let new_listing = Listing {
      number: market.listings.length(),
      price,
      item
    };
    market.listings.push_back(new_listing)
}

#[allow(lint(self_transfer))]
public fun delist(
    community: &Community,
    market: &mut Market,
    cap: &MarketCap,
    list_number: u64,
    ctx: &mut TxContext
) {
    let community_id = object::id(community);
    assert!(community_id == market.community_id);
    let market_id = object::id(market);
    assert!(market_id == cap.market_id);

    let listing = market.listings.remove(list_number);
    let Listing{number: _, price: _, item} = listing;
    transfer::public_transfer(item, ctx.sender());
}

#[allow(lint(self_transfer))]
public fun purchase_with_membership(
    community: &Community,
    market: &mut Market,
    membership: &Membership,
    list_number: u64,
    ctx: &mut TxContext
) {
    let community_id = object::id(community);
    assert!(community_id == market.community_id);
    assert!(community_id == membership.community_id());

    let listing = market.listings.remove(list_number);
    let Listing{number: _, price, item} = listing;

    // price 대신 꽁짜
    // let price_balance = payment.split<SUI>(price);
    // market.balance.join(price_balance);
    transfer::public_transfer(item, ctx.sender());


}

#[allow(lint(self_transfer))]
public fun purchase(
    community: &Community,
    market: &mut Market,
    list_number: u64,
    payment: &mut Balance<SUI>,
    ctx: &mut TxContext
) {
    let community_id = object::id(community);
    assert!(community_id == market.community_id);

    let listing = market.listings.remove(list_number);
    let Listing{number: _, price, item} = listing;

    let price_balance = payment.split<SUI>(price);
    market.balance.join(price_balance);
    transfer::public_transfer(item, ctx.sender());
}
