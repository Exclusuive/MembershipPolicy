module exclusuive::payment;

use exclusuive::community::{Community, has_permission, MarketManager};
use exclusuive::exclusuive_membership::{Membership, get_mut_uid_membership, get_membership_name};
use std::string::String;
use sui::balance::{Self, Balance};
use sui::dynamic_field;
use sui::sui::SUI;

public struct Market has key, store {
    id: UID,
    community_id: ID,
    balance: Balance<SUI>,
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

public struct MembershipPolicyKey<phantom Type: store + copy + drop> has copy, drop, store {
    community_id: ID,
    membership_name: String,
}

public struct TicketType has copy, drop, store {
    community_id: ID,
    ticket_name: String,
}

public struct TicketTypeKey<phantom Type: store + copy + drop> has copy, drop, store {
    community_id: ID,
    ticket_name: String,
}

public struct Ticket has store {
    name: String,
    value: u64,
}

public fun new_market(community: &mut Community, ctx: &mut TxContext) {
    let community_id = object::id(community);
    assert!(has_permission<MarketManager>(community, tx_context::sender(ctx)), ENotAuthorized);

    let market = Market {
        id: object::new(ctx),
        community_id,
        balance: balance::zero(),
    };

    transfer::share_object(market);
}

public fun new_ticket_type(
    community: &mut Community,
    market: &mut Market,
    ticket_name: String,
    ctx: &mut TxContext,
) {
    let community_id = object::id(community);
    assert!(has_permission<MarketManager>(community, tx_context::sender(ctx)), ENotAuthorized);
    assert!(
        !dynamic_field::exists_(
            &market.id,
            TicketTypeKey<TicketType> { community_id, ticket_name },
        ),
    );
    dynamic_field::add(
        &mut market.id,
        TicketTypeKey<TicketType> { community_id, ticket_name },
        TicketType { community_id, ticket_name },
    );
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

    // check if reward_ticket is a valid ticket type
    if (reward_ticket != b"".to_string()) {
        assert!(
            dynamic_field::exists_(
                &market.id,
                TicketTypeKey<TicketType> { community_id, ticket_name: reward_ticket },
            ),
        );
    };
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
    assert!(
        dynamic_field::exists_(
            &market.id,
            TicketTypeKey<TicketType> { community_id, ticket_name: reward_ticket },
        ),
    );
    let policy = dynamic_field::borrow_mut<MembershipPolicyKey<MembershipPolicy>, MembershipPolicy>(
        &mut market.id,
        MembershipPolicyKey<MembershipPolicy> { community_id, membership_name },
    );

    policy.discount_rate = discount_rate;
    policy.reward_ticket = reward_ticket;
    policy.reward_value = reward_value;
    policy.is_active = is_active;
}

public fun process_payment_without_membership(
    market: &mut Market,
    payment: &mut Balance<SUI>,
    price: u64,
) {
    let price_balance = payment.split<SUI>(price);
    market.balance.join(price_balance);
}

public fun process_payment_with_membership(
    community: &mut Community,
    market: &mut Market,
    payment: &mut Balance<SUI>,
    price: u64,
    membership: &mut Membership,
) {
    let community_id = object::id(community);

    let membership_name = get_membership_name(membership);
    assert!(
        dynamic_field::exists_(
            &market.id,
            MembershipPolicyKey<MembershipPolicy> { community_id, membership_name },
        ),
    );
    let policy = dynamic_field::borrow<MembershipPolicyKey<MembershipPolicy>, MembershipPolicy>(
        &market.id,
        MembershipPolicyKey<MembershipPolicy> { community_id, membership_name },
    );

    if (policy.is_active) {
        let discount_rate = policy.discount_rate;
        let reward_ticket = policy.reward_ticket;
        let reward_value = policy.reward_value;

        if (reward_ticket != b"".to_string()) {
            if (
                dynamic_field::exists_(
                    get_mut_uid_membership(membership),
                    TicketTypeKey<TicketType> { community_id, ticket_name: reward_ticket },
                )
            ) {
                let ticket = dynamic_field::borrow_mut<TicketTypeKey<TicketType>, Ticket>(
                    get_mut_uid_membership(membership),
                    TicketTypeKey<TicketType> { community_id, ticket_name: reward_ticket },
                );
                ticket.value = ticket.value + reward_value;
            } else {
                let ticket = Ticket {
                    name: reward_ticket,
                    value: reward_value,
                };
                dynamic_field::add(
                    get_mut_uid_membership(membership),
                    TicketTypeKey<TicketType> { community_id, ticket_name: reward_ticket },
                    ticket,
                );
            };
        };
        if (discount_rate > 0) {
            let discount_price = price * (10000 - discount_rate) / 10000;
            let discount_balance = payment.split<SUI>(discount_price);
            market.balance.join(discount_balance);
        };
    } else {
        let price_balance = payment.split<SUI>(price);
        market.balance.join(price_balance);
    }
}
