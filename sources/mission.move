// module exclusuive::mission;

// use exclusuive::community::{Community, CommunityCap, MissionManager, has_permission};
// use std::string::String;
// use sui::balance::{Self, Balance};
// use sui::dynamic_field;
// use sui::dynamic_object_field;
// use sui::sui::SUI;
// use sui::vec_set::{Self, VecSet};

// // use sui::dynamic_field;

// // use sui::vec_map::{Self, VecMap};

// public struct TicketType has copy, drop, store {
//     community_id: ID,
//     name: String,
// }

// public struct MissionDashboard has key, store {
//     id: UID,
//     community_id: ID,
//     balance: Balance<SUI>,
// }

// public struct Mission has key, store {
//     id: UID,
//     community_id: ID,
//     price: u64,
//     product: TicketType, // 지급할 상품 타입 (외부 팩토리 호출에 사용)
//     mode: u8, // 완료 모드
//     // 필요하면 name이나 metadata 추가
// }

// // ------- Dynamic Field Keys / Values -------

// /// 대시보드: 미션 이름으로 미션을 찾기 위함
// public struct MissionKey has copy, drop, store {
//     name: String,
// }

// /// 특정 미션에서 "이 주소가 완료했는지" 체크하기 위한 키
// public struct AddrKey has copy, drop, store {
//     user: address,
// }

// /// 완료 마커 (제로 사이즈)
// public struct Completed has copy, drop, store {}

// entry fun create_mission_dashboard(
//     community: &mut Community,
//     community_cap: &mut CommunityCap,
//     ctx: &mut TxContext,
// ) {
//     let dashboard = new_mission_dashboard(community, community_cap, ctx);
//     transfer::share_object(dashboard);
// }

// public fun new_mission_dashboard(
//     community: &mut Community,
//     community_cap: &mut CommunityCap,
// ): MissionDashboard {
//     let community_id = object::id(community);
//     assert!(community_id == community_cap.community_id);
//     let dashboard = MissionDashboard {
//         id: object::new(ctx),
//         community_id,
//         balance: balance::zero(),
//     };
//     dashboard
// }

// public fun new_ticket_type(
//     community: &mut Community,
//     dashboard: &mut MissionDashboard,
//     ticket_name: String,
//     ctx: &mut TxContext,
// ): TicketType {
//     let community_id = object::id(community);
//     assert!(has_permission<MissionManager>(community, ctx.sender()));

//     let ticket_type = TicketType {
//         id: object::new(ctx),
//         community_id,
//         name,
//     };
//     dynamic_field::add(
//         &mut dashboard.id,
//         TicketTypeKey {
//             community_id,
//             dashboard_id: object::id(dashboard),
//             name: ticket_name,
//         },
//         ticket_type,
//     );
//     ticket_type
// }

// public fun new_mission(
//     community: &mut Community,
//     mission_dashboard: &mut MissionDashboard,
//     name: String,
//     price: u64,
//     product: TicketType,
//     mode: u8,
// ) {
//     let community_id = object::id(community);
//     assert!(community_id == mission_dashboard.community_id);
//     assert!(has_permission<MissionManager>(community, ctx.sender()));

//     let mission = Mission {
//         id: object::new(community_id),
//         community_id,
//         price,
//         product,
//         mode,
//     };
// }
