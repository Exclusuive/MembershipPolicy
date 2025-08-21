module exclusuive::reward;

use exclusuive::community::{Community, has_permission, get_mut_uid, MarketManager};
use std::string::String;
use sui::dynamic_field;

const ENotAuthorized: u64 = 1;

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

public fun new_ticket_type(community: &mut Community, ticket_name: String, ctx: &mut TxContext) {
    let community_id = object::id(community);
    assert!(has_permission<MarketManager>(community, tx_context::sender(ctx)), ENotAuthorized);
    assert!(
        !dynamic_field::exists_(
            get_mut_uid(community),
            TicketTypeKey<TicketType> { community_id, ticket_name },
        ),
    );
    dynamic_field::add(
        get_mut_uid(community),
        TicketTypeKey<TicketType> { community_id, ticket_name },
        TicketType { community_id, ticket_name },
    );
}

public(package) fun add_ticket_value(ticket: &mut Ticket, value: u64) {
    ticket.value = ticket.value + value;
}

public(package) fun new_ticket(ticket_name: String, value: u64): Ticket {
    Ticket {
        name: ticket_name,
        value: value,
    }
}

public fun check_ticket_type(community: &mut Community, ticket_name: String): bool {
    let community_id = object::id(community);
    if (
        dynamic_field::exists_(
            get_mut_uid(community),
            TicketTypeKey<TicketType> { community_id, ticket_name },
        )
    ) {
        true
    } else {
        false
    }
}
