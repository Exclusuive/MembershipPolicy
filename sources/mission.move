// module exclusuive::mission;

// use exclusuive::community::TicketType;
// use std::string::String;
// use std::type_name::{Self, TypeName};
// use sui::balance::{Self, Balance};
// use sui::dynamic_field;
// use sui::sui::SUI;
// use sui::vec_map::{Self, VecMap};

// public struct MissionFactory has key, store {
//     id: UID,
//     community_id: ID,
//     missions: VecMap<String, Mission>,
//     balance: Balance<SUI>,
// }

// public struct MissionFactoryCap has key, store {
//     id: UID,
//     community_id: ID,
// }

// public struct Mission has store {
//     conditions: vector<Condition>,
//     price: u64,
//     product: TypeName,
// }

// public struct OffChainMission has store {}

// public struct Condition has copy, drop, store {
//     ticket_type: TicketType,
//     requirement: u64,
// }

// public struct PurchaseRequest {
//     mission_factory_id: ID,
//     mission_name: String,
//     paid: u64,
//     receipts: VecMap<TicketType, u64>,
// }
