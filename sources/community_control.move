// module exclusuive::community_control;

// use exclusuive::community::{Community, CommunityCap};
// use std::string::String;

// public struct CommunityControlCap has key, store {
//     id: UID,
//     community_id: ID,
//     name: String,
//     admin_address: address,
// }

// public struct CommunityControl has key {
//     id: UID,
//     community_id: ID,
//     kiosk_id: ID,
//     // 기타 공유되는 데이터들
// }

// fun init(ctx: &mut TxContext, community: Community, community_cap: CommunityCap) {
//     let cap = CommunityControl {
//         id: ctx.sender(),
//         community_id,
//         name,
//         admin_address,
//     };
// }
