module exclusuive::membership_tests;

use exclusuive::community;
use exclusuive::exclusuive_membership;
use std::string;
use sui::test_scenario as ts;

const COMMUNITY_CREATOR: address = @0xCCCC;
// const COMMUNITY_MANAGER: address = @0xAAAA;
const MEMBERSHIP_MANAGER: address = @0xBBBB;
// const MEMBERSHIP_USER: address = @0xDDDD;

#[test]
fun test_register_membership_type_success() {
    let mut ts = ts::begin(COMMUNITY_CREATOR);
    community::create_community(ts.ctx());

    ts.next_tx(COMMUNITY_CREATOR);
    let mut community = ts.take_shared<community::Community>();
    let mut cap: community::CommunityCap = ts.take_from_sender();

    // grant permission
    community::grant_permission<community::MembershipManager>(
        &mut community,
        &mut cap,
        MEMBERSHIP_MANAGER,
    );
    ts::return_shared(community);
    ts.return_to_sender(cap);

    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();

    // register membership type
    exclusuive_membership::new_membership_type(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"VIP_description"),
        true,
        true,
        ts.ctx(),
    );
    ts::return_shared(community);

    ts.end();
}

#[test]
#[expected_failure(abort_code = exclusuive_membership::ENotAuthorized)]
fun test_register_membership_type_without_permission_fail() {
    let mut ts = ts::begin(COMMUNITY_CREATOR);
    community::create_community(ts.ctx());

    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();

    // register membership type
    exclusuive_membership::new_membership_type(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"VIP_description"),
        true,
        true,
        ts.ctx(),
    );
    abort 0xbad
}

#[test]
#[expected_failure(abort_code = exclusuive_membership::EAlreadyExists)]
fun test_register_membership_type_with_same_name_fail() {
    let mut ts = ts::begin(COMMUNITY_CREATOR);
    community::create_community(ts.ctx());

    ts.next_tx(COMMUNITY_CREATOR);
    let mut community = ts.take_shared<community::Community>();
    let mut cap: community::CommunityCap = ts.take_from_sender();

    // grant permission
    community::grant_permission<community::MembershipManager>(
        &mut community,
        &mut cap,
        MEMBERSHIP_MANAGER,
    );
    ts::return_shared(community);
    ts.return_to_sender(cap);

    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();

    // register membership type
    exclusuive_membership::new_membership_type(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"VIP_description"),
        true,
        true,
        ts.ctx(),
    );

    exclusuive_membership::new_membership_type(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"VIP_description"),
        true,
        true,
        ts.ctx(),
    );

    abort 0xbad
}

#[test]
fun test_update_membership_type_success() {
    let mut ts = ts::begin(COMMUNITY_CREATOR);
    community::create_community(ts.ctx());

    ts.next_tx(COMMUNITY_CREATOR);
    let mut community = ts.take_shared<community::Community>();
    let mut cap: community::CommunityCap = ts.take_from_sender();

    // grant permission
    community::grant_permission<community::MembershipManager>(
        &mut community,
        &mut cap,
        MEMBERSHIP_MANAGER,
    );
    ts::return_shared(community);
    ts.return_to_sender(cap);

    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();

    // register membership type
    exclusuive_membership::new_membership_type(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"VIP_description"),
        true,
        true,
        ts.ctx(),
    );
    ts::return_shared(community);

    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();

    // update membership type
    exclusuive_membership::update_membership_type(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"VIP_description"),
        false,
        true,
        ts.ctx(),
    );
    ts::return_shared(community);

    ts.end();
}

#[test]
#[expected_failure(abort_code = exclusuive_membership::EObjectNotExist)]
fun test_update_membership_type_with_wrong_name_fail() {
    let mut ts = ts::begin(COMMUNITY_CREATOR);
    community::create_community(ts.ctx());

    ts.next_tx(COMMUNITY_CREATOR);
    let mut community = ts.take_shared<community::Community>();
    let mut cap: community::CommunityCap = ts.take_from_sender();

    // grant permission
    community::grant_permission<community::MembershipManager>(
        &mut community,
        &mut cap,
        MEMBERSHIP_MANAGER,
    );
    ts::return_shared(community);
    ts.return_to_sender(cap);

    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();

    // register membership type
    exclusuive_membership::new_membership_type(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"VIP_description"),
        true,
        true,
        ts.ctx(),
    );

    exclusuive_membership::update_membership_type(
        &mut community,
        string::utf8(b"VIP2"),
        string::utf8(b"VIP_description2"),
        false,
        true,
        ts.ctx(),
    );

    abort 0xbad
}

#[test]
fun test_mint_membership_with_permission_success() {
    let mut ts = ts::begin(COMMUNITY_CREATOR);
    community::create_community(ts.ctx());

    // ===== 1. COMMUNITY_CREATOR → grant permission to MEMBERSHIP_MANAGER
    ts.next_tx(COMMUNITY_CREATOR);
    let mut community = ts.take_shared<community::Community>();
    let mut cap: community::CommunityCap = ts.take_from_sender();
    community::grant_permission<community::MembershipManager>(
        &mut community,
        &mut cap,
        MEMBERSHIP_MANAGER,
    );
    ts::return_shared(community);
    ts.return_to_sender(cap);

    // ===== 2. MEMBERSHIP_MANAGER → register MembershipType
    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();
    exclusuive_membership::new_membership_type(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"VIP_description"),
        false, // 일반 유저 mint 불가
        true,
        ts.ctx(),
    );
    ts::return_shared(community);

    // ===== 3. MEMBERSHIP_MANAGER → mint Membership (성공)
    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();
    exclusuive_membership::mint_membership(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"img_url"),
        MEMBERSHIP_MANAGER,
        ts.ctx(),
    );
    ts::return_shared(community);

    ts.end();
}

#[test]
#[expected_failure(abort_code = exclusuive_membership::ENotAuthorized)]
fun test_mint_membership_without_permission_fail() {
    let mut ts = ts::begin(COMMUNITY_CREATOR);
    community::create_community(ts.ctx());

    // ===== 1. COMMUNITY_CREATOR → grant permission to MEMBERSHIP_MANAGER
    ts.next_tx(COMMUNITY_CREATOR);
    let mut community = ts.take_shared<community::Community>();
    let mut cap: community::CommunityCap = ts.take_from_sender();
    community::grant_permission<community::MembershipManager>(
        &mut community,
        &mut cap,
        MEMBERSHIP_MANAGER,
    );
    ts::return_shared(community);
    ts.return_to_sender(cap);

    // ===== 2. MEMBERSHIP_MANAGER → register MembershipType (user mint 불가)
    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();
    exclusuive_membership::new_membership_type(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"VIP_description"),
        false, // ❌ 일반 유저 mint 불가
        true,
        ts.ctx(),
    );
    ts::return_shared(community);

    // ===== 3. 일반 유저 → mint Membership (실패해야 함)
    let random_user: address = @0xDDDD;
    ts.next_tx(random_user);
    let mut community = ts.take_shared<community::Community>();
    exclusuive_membership::mint_membership(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"img_url"),
        random_user,
        ts.ctx(),
    );

    abort 0xbad
}

#[test]
fun test_mint_membership_with_user_mint_allowed_success() {
    let mut ts = ts::begin(COMMUNITY_CREATOR);
    community::create_community(ts.ctx());

    // ===== 1. COMMUNITY_CREATOR → grant permission
    ts.next_tx(COMMUNITY_CREATOR);
    let mut community = ts.take_shared<community::Community>();
    let mut cap: community::CommunityCap = ts.take_from_sender();
    community::grant_permission<community::MembershipManager>(
        &mut community,
        &mut cap,
        MEMBERSHIP_MANAGER,
    );
    ts::return_shared(community);
    ts.return_to_sender(cap);

    // ===== 2. MEMBERSHIP_MANAGER → register MembershipType (user mint 허용)
    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();
    exclusuive_membership::new_membership_type(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"VIP_description"),
        true, // ✅ 일반 유저 mint 허용
        true,
        ts.ctx(),
    );
    ts::return_shared(community);

    // ===== 3. 일반 유저 → mint Membership (성공해야 함)
    let random_user: address = @0xDDDD;
    ts.next_tx(random_user);
    let mut community = ts.take_shared<community::Community>();
    exclusuive_membership::mint_membership(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"img_url"),
        random_user,
        ts.ctx(),
    );
    ts::return_shared(community);

    ts.end();
}

#[test]
#[expected_failure(abort_code = exclusuive_membership::EObjectNotExist)]
fun test_mint_membership_with_nonexistent_type_fail() {
    let mut ts = ts::begin(COMMUNITY_CREATOR);
    community::create_community(ts.ctx());

    // ===== 1. 일반 유저가 존재하지 않는 MembershipType으로 mint 시도 (실패해야 함)
    let random_user: address = @0xDDDD;
    ts.next_tx(random_user);
    let mut community = ts.take_shared<community::Community>();
    exclusuive_membership::mint_membership(
        &mut community,
        string::utf8(b"NOT_EXIST"),
        string::utf8(b"img_url"),
        random_user,
        ts.ctx(),
    );

    abort 0xbad
}

#[test]
fun test_update_membership_success() {
    let mut ts = ts::begin(COMMUNITY_CREATOR);
    community::create_community(ts.ctx());

    // ===== 1. COMMUNITY_CREATOR → grant permission
    ts.next_tx(COMMUNITY_CREATOR);
    let mut community = ts.take_shared<community::Community>();
    let mut cap: community::CommunityCap = ts.take_from_sender();
    community::grant_permission<community::MembershipManager>(
        &mut community,
        &mut cap,
        MEMBERSHIP_MANAGER,
    );
    ts::return_shared(community);
    ts.return_to_sender(cap);

    // ===== 2. MEMBERSHIP_MANAGER → register MembershipType
    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();
    exclusuive_membership::new_membership_type(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"VIP_description"),
        true,
        false, // transfer 불가
        ts.ctx(),
    );
    ts::return_shared(community);

    // ===== 3. MEMBERSHIP_MANAGER → mint Membership
    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();
    let mut m: exclusuive_membership::Membership = exclusuive_membership::new_membership(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"img_url"),
        ts.ctx(),
    );
    ts::return_shared(community);

    // ===== 4. MEMBERSHIP_MANAGER → update MembershipType (transfer 허용)
    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();
    exclusuive_membership::update_membership_type(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"VIP_description"),
        true,
        true, // ✅ transfer 허용으로 변경
        ts.ctx(),
    );
    ts::return_shared(community);

    // ===== 5. MEMBERSHIP_MANAGER → sync Membership with updated type
    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();
    exclusuive_membership::update_membership(&mut community, &mut m, ts.ctx());
    ts::return_shared(community);

    // 이후 m.allow_transfer == true 가 되어야 transfer 가능
    exclusuive_membership::transfer(m, MEMBERSHIP_MANAGER);

    ts.end();
}

#[test]
fun test_transfer_success_when_allowed() {
    let mut ts = ts::begin(COMMUNITY_CREATOR);
    community::create_community(ts.ctx());

    // ===== 1. COMMUNITY_CREATOR → grant permission
    ts.next_tx(COMMUNITY_CREATOR);
    let mut community = ts.take_shared<community::Community>();
    let mut cap: community::CommunityCap = ts.take_from_sender();
    community::grant_permission<community::MembershipManager>(
        &mut community,
        &mut cap,
        MEMBERSHIP_MANAGER,
    );
    ts::return_shared(community);
    ts.return_to_sender(cap);

    // ===== 2. MEMBERSHIP_MANAGER → register MembershipType (transfer 허용)
    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();
    exclusuive_membership::new_membership_type(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"VIP_description"),
        true,
        true, // ✅ transfer 허용
        ts.ctx(),
    );
    ts::return_shared(community);

    // ===== 3. MEMBERSHIP_MANAGER → mint Membership
    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();
    let m: exclusuive_membership::Membership = exclusuive_membership::new_membership(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"img_url"),
        ts.ctx(),
    );
    ts::return_shared(community);

    // ===== 4. transfer (성공해야 함)
    exclusuive_membership::transfer(m, @0xEEEE);

    ts.end();
}

#[test]
#[expected_failure(abort_code = exclusuive_membership::ENotAuthorized)]
fun test_transfer_fail_when_not_allowed() {
    let mut ts = ts::begin(COMMUNITY_CREATOR);
    community::create_community(ts.ctx());

    // ===== 1. COMMUNITY_CREATOR → grant permission
    ts.next_tx(COMMUNITY_CREATOR);
    let mut community = ts.take_shared<community::Community>();
    let mut cap: community::CommunityCap = ts.take_from_sender();
    community::grant_permission<community::MembershipManager>(
        &mut community,
        &mut cap,
        MEMBERSHIP_MANAGER,
    );
    ts::return_shared(community);
    ts.return_to_sender(cap);

    // ===== 2. MEMBERSHIP_MANAGER → register MembershipType (transfer 불가)
    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();
    exclusuive_membership::new_membership_type(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"VIP_description"),
        true,
        false, // ❌ transfer 불가
        ts.ctx(),
    );
    ts::return_shared(community);

    // ===== 3. MEMBERSHIP_MANAGER → mint Membership
    ts.next_tx(MEMBERSHIP_MANAGER);
    let mut community = ts.take_shared<community::Community>();
    let m: exclusuive_membership::Membership = exclusuive_membership::new_membership(
        &mut community,
        string::utf8(b"VIP"),
        string::utf8(b"img_url"),
        ts.ctx(),
    );
    ts::return_shared(community);

    // ===== 4. transfer 시도 (실패해야 함)
    exclusuive_membership::transfer(m, @0xEEEE);

    abort 0xbad
}
