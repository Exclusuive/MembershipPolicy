module exclusuive::sample_collection;

use std::string::{String};
use sui::dynamic_object_field;

public struct SampleCollection has key {
  id: UID,
  banner_url: String
}

public struct SampleNFT has key, store {
  id: UID,
  collection: ID,
}

public struct SampleLayer has key, store {
  id: UID,
  name: String
}

public struct SampleItem has key, store {
  id: UID,
  name: String,
  url: String,
  layer_name: String,
}

fun init(ctx: &mut TxContext) {
  let banner_url = b"https://file.notion.so/f/f/58b160c3-fe00-4852-8c42-471415797086/812a9abf-8e63-41ad-be9a-7f21053d52b8/%EB%85%B8%EC%85%98_%EC%A4%91%EA%B0%84_%EC%9D%B4%EB%AF%B8%EC%A7%80_24-2.png?table=block&id=39bc1ece-963f-424a-8dd8-3131e89408bc&spaceId=58b160c3-fe00-4852-8c42-471415797086&expirationTimestamp=1742472000000&signature=fCAaHiXd5G-ZiC-hHh0rsdqni_IUnuIUQvneONaW21g&downloadName=%EB%85%B8%EC%85%98+%EC%A4%91%EA%B0%84+%EC%9D%B4%EB%AF%B8%EC%A7%80+24-2.png".to_string();
  let collection = new_collection(banner_url, ctx);

  let mut nft = new_nft(&collection, ctx);

  let layer1 = b"background".to_string();
  let layer2 = b"character".to_string();
  let layer3 = b"cloth".to_string();

  nft.add_layer(layer1, ctx);
  nft.add_layer(layer2, ctx);
  nft.add_layer(layer3, ctx);

  let item1 = b"fire".to_string();
  let item2 = b"basic".to_string();
  let item3 = b"doctor".to_string();

  let item_url1 = b"https://myyonseinft.s3.us-east-1.amazonaws.com/MAJOR/test/background.PNG".to_string();
  let item_url2 = b"https://myyonseinft.s3.us-east-1.amazonaws.com/MAJOR/test/character.png".to_string();
  let item_url3 = b"https://myyonseinft.s3.us-east-1.amazonaws.com/MAJOR/test/clothes.PNG".to_string();

  nft.add_item(layer1, item1, item_url1, ctx);
  nft.add_item(layer2, item2, item_url2, ctx);
  nft.add_item(layer3, item3, item_url3, ctx);

  transfer::share_object(collection);
  transfer::transfer(nft, ctx.sender());

}



public fun new_collection(banner_url: String, ctx: &mut TxContext): SampleCollection {
  SampleCollection{
    id: object::new(ctx),
    banner_url
  }
}

public fun new_nft(collection: &SampleCollection, ctx: &mut TxContext): SampleNFT {
  let nft = SampleNFT {
    id: object::new(ctx),
    collection: object::id(collection),
  };

  nft
}

public fun add_layer(nft: &mut SampleNFT, layer_name: String, ctx: &mut TxContext) {
  dynamic_object_field::add(&mut nft.id, layer_name, SampleLayer{
    id: object::new(ctx),
    name: layer_name
  })
}

public fun add_item(nft: &mut SampleNFT, layer_name: String, item_name: String, item_url: String, ctx: &mut TxContext) {
  let layer = dynamic_object_field::borrow_mut<String, SampleLayer>(&mut nft.id, layer_name);

  dynamic_object_field::add(&mut layer.id, item_name, SampleItem{
    id: object::new(ctx),
    name: item_name,
    url: item_url,
    layer_name
  })
}