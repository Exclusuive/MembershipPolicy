#[test_only]
module exclusuive::exclusuive_tests;
// uncomment this line to import the module
use exclusuive::collection::{Self, Item, PropertyScroll, Ticket, LayerType, PropertyType, TicketType};
use std::debug;


public struct EXCLUSUIVE_TESTS has drop {}

use sui::package::test_claim;

const ENotImplemented: u64 = 0;

#[test]
fun test_collection() {
    let mut ctx = tx_context::dummy();
    let pub = test_claim(EXCLUSUIVE_TESTS{}, &mut ctx);

    // Collection 준비
    let collection_name = b"Dokpami".to_string();
    let (mut collection, col_cap) = collection::new(collection_name, &mut ctx);

    // Type 추가
    let layer_type = b"Background".to_string();
    collection::add_layer_type(&mut collection, &col_cap, layer_type);

    let layer_type2 = b"Background2".to_string();
    collection::add_layer_type(&mut collection, &col_cap, layer_type2);

    let property_type = b"Strong".to_string();
    collection::add_property_type(&mut collection, &col_cap, property_type);

    let ticket_type = b"RedTicket".to_string();
    collection::add_ticket_type(&mut collection, &col_cap, ticket_type);

    // Store 준비 
    let store_name = b"JaPaanKi".to_string();
    let (mut store, store_cap) = collection::new_store(&collection, store_name, &mut ctx);

    // Store에 Slot 추가
    //0
    collection::add_slot_to_store<Ticket>(&collection, &mut store, &store_cap, 0);
    //1
    collection::add_slot_to_store<PropertyScroll>(&collection, &mut store, &store_cap, 0);

    // Slot에 Product 추가
    let ticket = collection::new_ticket(&collection, &col_cap, ticket_type, &mut ctx);
    let slot_number = 0;
    collection::add_product_to_store(&collection, &mut store, &store_cap, slot_number, ticket);

    let property_scroll = collection::new_property_scroll(&collection, &col_cap, property_type, 3, &mut ctx);
    let slot_number = 1;
    collection::add_product_to_store(&collection, &mut store, &store_cap, slot_number, property_scroll);

    // Slot에 Condition 추가
    let slot_number = 1;
    let requirement = 1;
    collection::add_condition_to_slot(&collection,&mut store, &store_cap, slot_number, ticket_type, requirement);

    // Request
    // Type Argument 잘 확인하자?
    {
        // Request1
        let slot_number = 0;
        let request = collection::new_request(&collection, &mut store, slot_number);
        let ticket1_product = collection::confirm_request<Ticket>(&collection, &mut store, request);
        
        // Request2
        let slot_number = 1;
        let mut request = collection::new_request(&collection, &mut store, slot_number);
        collection::burn_ticket(&collection, &store, &mut request, ticket1_product);
        let propertyscroll1_product = collection::confirm_request<PropertyScroll>(&collection, &mut store, request);

        transfer::public_transfer(propertyscroll1_product, ctx.sender());
    };
    
    // Data 정리
    transfer::public_transfer(pub, ctx.sender());
    transfer::public_share_object(collection);
    transfer::public_transfer(col_cap, ctx.sender());
    transfer::public_share_object(store);
    transfer::public_transfer(store_cap, ctx.sender());

    // pass
}

#[test, expected_failure(abort_code = ::exclusuive::exclusuive_tests::ENotImplemented)]
fun test_exclusuive_fail() {
    abort ENotImplemented
}