module exclusuive::payment_tests_with_testcoin;

use exclusuive::community;
use exclusuive::exclusuive_membership;
use exclusuive::payment;
use exclusuive::reward;
use exclusuive::test_usdc::{Self, TEST_USDC};
use std::string;
use sui::coin::{Self as coin, Coin, TreasuryCap};
use sui::test_scenario as ts;

// =========================
// Test addresses
// =========================
const CREATOR: address = @0xAAA1;
const MANAGER: address = @0xBBB2;
const USER: address = @0xCCC3;

// =========================
// Test-only fungible token: USDC
// =========================

/// 통화(USDC) 생성: TreasuryCap 발급 (MANAGER가 들고 있게 함)
fun create_test_currency_usdc(t: &mut ts::Scenario) {
    t.next_tx(MANAGER);
    test_usdc::init_for_testing(t.ctx());
}

/// MANAGER가 USDC를 mint하여 지정 주소로 전송
fun mint_usdc_to(t: &mut ts::Scenario, to: address, amount: u64) {
    t.next_tx(MANAGER);
    let mut cap: TreasuryCap<TEST_USDC> = t.take_from_sender();
    let c: Coin<TEST_USDC> = coin::mint(&mut cap, amount, t.ctx());
    // cap은 다시 MANAGER에게
    t.return_to_sender(cap);
    // 코인을 받는 사람에게 전송
    transfer::public_transfer(c, to);
}

// =========================
// Common setup helpers
// =========================

/// 커뮤니티 생성 + MarketManager 권한 부여 + 마켓 생성
fun setup_market(t: &mut ts::Scenario): (community::Community, payment::Market) {
    let (com, cap) = community::new_community(t.ctx());
    transfer::public_transfer(cap, CREATOR);
    transfer::public_share_object(com);

    // CREATOR -> MANAGER 에 MarketManager 권한 부여
    t.next_tx(CREATOR);
    let mut com = t.take_shared<community::Community>();
    let mut cap: community::CommunityCap = t.take_from_sender();
    community::grant_permission<community::MarketManager>(&mut com, &mut cap, MANAGER);
    ts::return_shared(com);
    t.return_to_sender(cap);

    // MANAGER -> 마켓 생성
    t.next_tx(MANAGER);
    let mut com2 = t.take_shared<community::Community>();
    payment::new_market(&mut com2, t.ctx());
    t.next_tx(MANAGER);
    let market: payment::Market = t.take_shared();

    (com2, market)
}

/// MembershipType "VIP" 등록 + USER에게 멤버십 발급 (user mint 허용)
fun setup_membership_vip(t: &mut ts::Scenario) {
    // CREATOR -> MembershipManager 권한을 MANAGER에 부여
    t.next_tx(CREATOR);
    let mut com = t.take_shared<community::Community>();
    let mut cap: community::CommunityCap = t.take_from_sender();
    community::grant_permission<community::MembershipManager>(&mut com, &mut cap, MANAGER);
    ts::return_shared(com);
    t.return_to_sender(cap);

    // MANAGER -> VIP 등록 (user mint 허용)
    t.next_tx(MANAGER);
    let mut com2 = t.take_shared<community::Community>();
    exclusuive_membership::new_membership_type(
        &mut com2,
        string::utf8(b"VIP"),
        string::utf8(b"vip_desc"),
        true, // user mint 허용
        true, // transfer 허용
        t.ctx(),
    );
    ts::return_shared(com2);

    // USER -> VIP 멤버십 mint
    t.next_tx(USER);
    let mut com3 = t.take_shared<community::Community>();
    let _m: exclusuive_membership::Membership = exclusuive_membership::new_membership(
        &mut com3,
        string::utf8(b"VIP"),
        string::utf8(b"img"),
        t.ctx(),
    );
    transfer::public_transfer(_m, USER);
    ts::return_shared(com3);
}

// =========================
// Tests
// =========================

/// 1) 비회원 결제(USDC) → withdraw<USDC>() 로 인출 확인
#[test]
fun test_usdc_payment_without_membership_and_withdraw() {
    let mut t = ts::begin(CREATOR);

    // 커뮤니티/마켓 + 테스트코인(USDC) 생성
    let (_com, _market) = setup_market(&mut t);
    create_test_currency_usdc(&mut t);
    transfer::public_share_object(_com);
    transfer::public_share_object(_market);

    // USER에게 USDC 500 발행
    mint_usdc_to(&mut t, USER, 500);

    // USER tx: 결제 200 USDC
    t.next_tx(USER);
    let mut market = t.take_shared<payment::Market>();
    let mut pay: Coin<TEST_USDC> = t.take_from_sender(); // 방금 받은 500 USDC
    // 결제 전 200만큼 분리하여 사용
    payment::process_payment_without_membership<TEST_USDC>(
        &mut market,
        &mut pay,
        200,
        t.ctx(),
    );
    // 남은 코인은 다시 사용자에게 반환
    transfer::public_transfer(pay, USER);
    ts::return_shared(market);

    // MANAGER tx: withdraw<USDC>() → 마켓 보관분 전액 인출(200)
    t.next_tx(MANAGER);
    let mut com2 = t.take_shared<community::Community>();
    let mut market2 = t.take_shared<payment::Market>();
    payment::withdraw<TEST_USDC>(&mut com2, &mut market2, t.ctx());
    // 인출 코인이 MANAGER에게 도착

    t.next_tx(MANAGER);
    let c: Coin<TEST_USDC> = t.take_from_sender();
    assert!(coin::value(&c) == 200, 1);
    // 정리
    ts::return_shared(com2);
    ts::return_shared(market2);
    t.return_to_sender(c);
    t.end();
}

/// 2) 회원 결제(USDC, 할인 + 리워드) → withdraw 금액이 할인 반영
#[test]
fun test_usdc_payment_with_membership_discount_and_withdraw() {
    let mut t = ts::begin(CREATOR);

    // 커뮤니티/마켓 + USDC 발행 + VIP 멤버십 준비
    let (mut com, _market) = setup_market(&mut t);
    transfer::public_share_object(com);
    transfer::public_share_object(_market);
    create_test_currency_usdc(&mut t);
    setup_membership_vip(&mut t);

    t.next_tx(MANAGER);
    let mut com = t.take_shared<community::Community>();
    let mut _market = t.take_shared<payment::Market>();

    // 리워드 티켓 타입 등록(POINT) - payment.new_membership_policy 에서 검사 통과용
    reward::new_ticket_type(&mut com, string::utf8(b"POINT"), t.ctx());
    ts::return_shared(com);
    ts::return_shared(_market);

    // 정책: VIP, 할인 10%(1000), 리워드(POINT, 5), 활성화
    t.next_tx(MANAGER);
    let mut com2 = t.take_shared<community::Community>();
    let mut market2 = t.take_shared<payment::Market>();
    payment::new_membership_policy(
        &mut com2,
        &mut market2,
        string::utf8(b"VIP"),
        1000,
        string::utf8(b"POINT"),
        5,
        true,
        t.ctx(),
    );
    ts::return_shared(com2);
    ts::return_shared(market2);

    // USER에게 USDC 100 발행
    mint_usdc_to(&mut t, USER, 100);

    // USER tx: 멤버십 + 결제
    t.next_tx(USER);
    let mut com3 = t.take_shared<community::Community>();
    let mut market3 = t.take_shared<payment::Market>();
    let mut m: exclusuive_membership::Membership = t.take_from_sender(); // USER가 가진 VIP 멤버십
    let mut pay: Coin<TEST_USDC> = t.take_from_sender(); // 방금 받은 100 USDC

    // 가격 100, 할인 10% → 90만 지불
    payment::process_payment_with_membership<TEST_USDC>(
        &mut com3,
        &mut market3,
        &mut pay,
        100,
        &mut m,
        t.ctx(),
    );
    // 남은 코인을 사용자에게 반환
    transfer::public_transfer(pay, USER);
    // 멤버십도 다시 사용자에게
    transfer::public_transfer(m, USER);
    ts::return_shared(com3);
    ts::return_shared(market3);

    // MANAGER tx: withdraw<USDC>() → 90
    t.next_tx(MANAGER);
    let mut com4 = t.take_shared<community::Community>();
    let mut market4 = t.take_shared<payment::Market>();
    payment::withdraw<TEST_USDC>(&mut com4, &mut market4, t.ctx());

    t.next_tx(MANAGER);
    let c: Coin<TEST_USDC> = t.take_from_sender();
    assert!(coin::value(&c) == 90, 2);
    ts::return_shared(com4);
    ts::return_shared(market4);
    t.return_to_sender(c);
    t.end();
}

/// 3) 정책이 없을 때 회원 결제 시도 → 실패해야 함
#[test]
#[expected_failure] // policy assert
fun test_usdc_payment_with_membership_fails_without_policy() {
    let mut t = ts::begin(CREATOR);

    let (mut com, _market) = setup_market(&mut t);
    ts::return_shared(com);
    t.return_to_sender(_market);
    create_test_currency_usdc(&mut t);
    setup_membership_vip(&mut t);

    // USER에게 USDC 50 발행
    mint_usdc_to(&mut t, USER, 50);

    // USER tx
    t.next_tx(USER);
    let mut com2 = t.take_shared<community::Community>();
    let mut market2 = t.take_shared<payment::Market>();
    let mut m: exclusuive_membership::Membership = t.take_from_sender();
    let mut pay: Coin<TEST_USDC> = t.take_from_sender();

    // 정책 미설정 상태에서 결제 시도 → assert로 실패해야 함
    payment::process_payment_with_membership<TEST_USDC>(
        &mut com2,
        &mut market2,
        &mut pay,
        50,
        &mut m,
        t.ctx(),
    );

    abort 0xbad
}

/// 4) withdraw 권한이 없으면 실패
#[test]
#[expected_failure(abort_code = payment::ENotAuthorized)]
fun test_withdraw_fails_without_permission() {
    let mut t = ts::begin(CREATOR);

    let (mut com, _market) = setup_market(&mut t);
    transfer::public_share_object(com);
    transfer::public_share_object(_market);
    create_test_currency_usdc(&mut t);

    // USER에게 USDC 10 발행
    mint_usdc_to(&mut t, USER, 10);

    // USER 결제 10
    t.next_tx(USER);
    let mut market2 = t.take_shared<payment::Market>();
    let mut pay: Coin<TEST_USDC> = t.take_from_sender();
    payment::process_payment_without_membership<TEST_USDC>(
        &mut market2,
        &mut pay,
        10,
        t.ctx(),
    );
    transfer::public_transfer(pay, USER); // 잔액 정리
    ts::return_shared(market2);

    // USER가 withdraw 시도 → 권한 없음으로 실패해야 함
    t.next_tx(USER);
    let mut com3 = t.take_shared<community::Community>();
    let mut market3 = t.take_shared<payment::Market>();
    payment::withdraw<TEST_USDC>(&mut com3, &mut market3, t.ctx());

    abort 0xbad
}
