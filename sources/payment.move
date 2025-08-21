module exclusuive::payment;

use exclusuive::community::{Community, has_permission, MarketManager};
use exclusuive::exclusuive_membership::{Membership, get_mut_uid_membership, get_membership_name};
use exclusuive::reward::{Ticket, TicketType, add_ticket_value, check_ticket_type, new_ticket};
use std::string::String;
use sui::balance::{Self, Balance};
use sui::coin::{Self, Coin};
use sui::dynamic_field;

public struct Market has key, store {
    id: UID,
    community_id: ID,
}

public struct MembershipPolicy has copy, drop, store {
    community_id: ID,
    membership_name: String,
    discount_rate: u64,
    reward_ticket: String,
    reward_value: u64,
    is_active: bool,
}

const ENotAuthorized: u64 = 1;
const EInvalidTicketType: u64 = 2;

public struct MembershipPolicyKey<phantom Type: store + copy + drop> has copy, drop, store {
    community_id: ID,
    membership_name: String,
}

public struct RewardKey<phantom Type: store + copy + drop> has copy, drop, store {
    community_id: ID,
    ticket_name: String,
}

public struct TokenKey<phantom T> has copy, drop, store {}

public fun new_market(community: &mut Community, ctx: &mut TxContext) {
    let community_id = object::id(community);
    assert!(has_permission<MarketManager>(community, tx_context::sender(ctx)), ENotAuthorized);

    let market = Market {
        id: object::new(ctx),
        community_id,
    };

    transfer::share_object(market);
}

public fun new_membership_policy(
    community: &mut Community,
    market: &mut Market,
    membership_name: String,
    discount_rate: u64,
    reward_ticket: String,
    reward_value: u64,
    is_active: bool,
    ctx: &mut TxContext,
) {
    let community_id = object::id(community);
    assert!(has_permission<MarketManager>(community, tx_context::sender(ctx)), ENotAuthorized);
    assert!(
        !dynamic_field::exists_(
            &market.id,
            MembershipPolicyKey<MembershipPolicy> { community_id, membership_name },
        ),
    );

    assert!(check_ticket_type(community, reward_ticket), EInvalidTicketType);

    dynamic_field::add(
        &mut market.id,
        MembershipPolicyKey<MembershipPolicy> { community_id, membership_name },
        MembershipPolicy {
            community_id,
            membership_name,
            discount_rate,
            reward_ticket,
            reward_value,
            is_active,
        },
    );
}

public fun update_membership_policy(
    community: &mut Community,
    market: &mut Market,
    membership_name: String,
    discount_rate: u64,
    reward_ticket: String,
    reward_value: u64,
    is_active: bool,
    ctx: &mut TxContext,
) {
    let community_id = object::id(community);
    assert!(has_permission<MarketManager>(community, tx_context::sender(ctx)), ENotAuthorized);
    assert!(
        dynamic_field::exists_(
            &market.id,
            MembershipPolicyKey<MembershipPolicy> { community_id, membership_name },
        ),
    );
    assert!(check_ticket_type(community, reward_ticket), EInvalidTicketType);
    let policy = dynamic_field::borrow_mut<MembershipPolicyKey<MembershipPolicy>, MembershipPolicy>(
        &mut market.id,
        MembershipPolicyKey<MembershipPolicy> { community_id, membership_name },
    );

    policy.discount_rate = discount_rate;
    policy.reward_ticket = reward_ticket;
    policy.reward_value = reward_value;
    policy.is_active = is_active;
}

/// 토큰 T용 balance가 없으면 생성
fun ensure_balance<T>(market: &mut Market) {
    if (!dynamic_field::exists_(&market.id, TokenKey<T> {})) {
        dynamic_field::add(
            &mut market.id,
            TokenKey<T> {},
            balance::zero<T>(),
        );
    };
}

/// 코인 입금 (Coin<T> → Balance<T>에 합치기)
public fun deposit<T>(market: &mut Market, c: Coin<T>) {
    ensure_balance<T>(market);
    let b = dynamic_field::borrow_mut<TokenKey<T>, Balance<T>>(&mut market.id, TokenKey<T> {});
    coin::put(b, c);
}

// membership 없이 결제
public fun process_payment_without_membership<T>(
    market: &mut Market,
    payment: &mut Coin<T>,
    price: u64,
    ctx: &mut TxContext,
) {
    let price_coin = coin::split(payment, price, ctx);
    deposit<T>(market, price_coin);
}

// membership 있는 결제
public fun process_payment_with_membership<T>(
    community: &mut Community,
    market: &mut Market,
    payment: &mut Coin<T>,
    price: u64,
    membership: &mut Membership,
    ctx: &mut TxContext,
) {
    let community_id = object::id(community);
    let membership_name = get_membership_name(membership);

    if (
        dynamic_field::exists_(
            &market.id,
            MembershipPolicyKey<MembershipPolicy> { community_id, membership_name },
        )
    ) {
        let policy = dynamic_field::borrow<MembershipPolicyKey<MembershipPolicy>, MembershipPolicy>(
            &market.id,
            MembershipPolicyKey<MembershipPolicy> { community_id, membership_name },
        );

        if (policy.is_active) {
            let discount_rate = policy.discount_rate;
            let reward_ticket = policy.reward_ticket;
            let reward_value = policy.reward_value;

            // === 리워드 티켓 적립 ===
            if (reward_ticket != b"".to_string()) {
                if (
                    dynamic_field::exists_(
                        get_mut_uid_membership(membership),
                        RewardKey<TicketType> { community_id, ticket_name: reward_ticket },
                    )
                ) {
                    let ticket = dynamic_field::borrow_mut<RewardKey<TicketType>, Ticket>(
                        get_mut_uid_membership(membership),
                        RewardKey<TicketType> { community_id, ticket_name: reward_ticket },
                    );
                    add_ticket_value(ticket, reward_value);
                } else {
                    let ticket = new_ticket(reward_ticket, reward_value);
                    dynamic_field::add(
                        get_mut_uid_membership(membership),
                        RewardKey<TicketType> { community_id, ticket_name: reward_ticket },
                        ticket,
                    );
                };
            };

            // === 할인 결제 ===
            let final_price = if (discount_rate > 0) {
                price * (10000 - discount_rate) / 10000
            } else {
                price
            };

            let pay_coin = coin::split(payment, final_price, ctx);
            deposit<T>(market, pay_coin);
        } else {
            // 정책 비활성화일 때 → 그냥 full price 결제
            let pay_coin = coin::split(payment, price, ctx);
            deposit<T>(market, pay_coin);
        }
    } else {
        let pay_coin = coin::split(payment, price, ctx);
        deposit<T>(market, pay_coin);
    };
}

#[allow(lint(self_transfer))]
public fun withdraw<T>(community: &mut Community, market: &mut Market, ctx: &mut TxContext) {
    assert!(has_permission<MarketManager>(community, tx_context::sender(ctx)), ENotAuthorized);
    ensure_balance<T>(market);
    let b = dynamic_field::borrow_mut<TokenKey<T>, Balance<T>>(&mut market.id, TokenKey<T> {});
    let balance = balance::withdraw_all(b);
    let coin = coin::from_balance(balance, ctx);
    transfer::public_transfer(coin, ctx.sender());
}
