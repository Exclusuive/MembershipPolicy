module exclusuive::membership_policy_v0;

use std::type_name::{Self, TypeName};
use std::string::{String};

use sui::package::{Self, Publisher};
use sui::balance::{Self, Balance};
use sui::sui::{SUI};
use sui::vec_set::{Self, VecSet};
use sui::dynamic_field;
use sui::dynamic_object_field;
// use sui::transfer_policy;

const ENotOwner: u64 = 100;
const ERuleAlreadySet: u64 = 101;

// Shared
public struct MembershipPolicy<phantom T: key> has key {
  id: UID,
  // rules: VecSet<TypeName>,
  balance: Balance<SUI>,
  version: u16,
}
// Owned
public struct MembershipPolicyCap<phantom T: key> has key, store {
  id: UID,
  policy_id: ID
}

// =============================================

public struct BaseKey<phantom T: key, phantom Config: store + drop> has store, drop, copy {}

public struct BaseConfig<phantom T: key, Config: store + drop> has store, copy, drop {
  img_url: String,
  cfg: Config,
}

public struct LayerKey<phantom T: key, phantom LayerType: store + drop, phantom Config: store + drop> has store, copy, drop{}

public struct LayerConfig<LayerType: store + drop, Config: store + drop> has store, copy, drop {
  `type`: LayerType,
  cfg: Config,
  order: u64,
}

public struct ItemKey<phantom T: key, phantom LayerType: store + drop, phantom Config: store + drop> has store, copy, drop {
  item_type: String
}

public struct ItemConfig<phantom T: key, LayerType: store + drop, Config: store + drop> has store, copy, drop {
  `type`: LayerType,
  cfg: Config,
  item_type: String,
  img_url: String,
}

public struct PropertyKey<phantom T: key, phantom PropertyType: store + drop, phantom Config: store + drop> has store, drop, copy {}

public struct PropertyConfig<phantom T: key, PropertyType: store + drop, Config: store + drop> has store, drop {
  `type`: PropertyType,
  cfg: Config,
  min: u64,
  max: u64,
}

// public struct RuleKey<phantom T: key, phantom Rule: drop> has copy, drop, store {}

//------------------------------------------------- 실제 Object Structs
// 이런게 필요할라나?
// public struct BaseBag<phantom T: key, Config: store + drop > has key, store {
//   id: UID,
//   cfg: BaseConfig<T, Config>,
// }

// // 아니면 이런거?
// public struct BaseWrapper<phantom T: key, Config: store + drop > has key, store {
//   id: UID,
//   cfg: BaseConfig<T, Config>,
// }

public struct Membership<T: key> has key, store {
  id: UID,
  base: Option<T>
}

public struct Layer<phantom T: key, LayerType: store + drop, Config: store + drop > has store {
  item_socket: Option<Item<T, LayerType, Config>>,
  cfg: LayerConfig<LayerType, Config>,
}

public struct Item<phantom T: key, LayerType: store + drop, Config: store + drop> has key, store {
  id: UID,
  cfg: ItemConfig<T, LayerType, Config>,
}

public struct Property<phantom T: key, PropertyType: store + drop, Config: store + drop> has store {
  value: u64,
  cfg: PropertyConfig<T, PropertyType, Config>
}

// =========================================

public struct TicketCollector<phantom T> has key {
  id: UID,
}


public struct MembershipRule {}
public struct ItemRule {}
public struct PropertyRule_Upgrade {}

public struct TicketKey<phantom T: key, phantom TicketType: drop> has store, drop, copy {}

public struct ATicket<phantom T: key, phantom TicketType: drop> {}
public struct LayerTicket<phantom T: key> {}
public struct ItemTicket<phantom T: key> {}
public struct PropertyTicket<phantom T: key> {}
public struct BTicket {}
public struct CTicket {}
public struct DTicket {}

// condition은 Shared Object?? 아니면 Immutable Object???
// Immutable이 오히려 괜찮을지도?? 뭔가 Package Upgrade 같이?? 그럼 버젼??
public struct Condition<phantom T: key> has key {
  id: UID
}
public struct BCondition {}

// public struct AMembership<phantom T: key> {}

public struct MembershipRequest<phantom T: key> {
    /// The ID of the transferred item. Although the `T` has no
    /// constraints, the main use case for this module is to work
    /// with Objects.
    item: ID,
    /// Amount of SUI paid for the item. Can be used to
    /// calculate the fee / transfer policy enforcement.
    paid: u64,
    /// The ID of the Kiosk / Safe the object is being sold from.
    /// Can be used by the TransferPolicy implementors.
    from: ID,
    /// Collected Receipts. Used to verify that all of the rules
    /// were followed and `TransferRequest` can be confirmed.
    receipts: VecSet<TypeName>,
}


// public struct CollectionRequest<phantom T: key> {}

// public struct ConvertRequest<phantom T: key> {}


// -------------------------- Admin Functions

public fun new<T: key>(pub: &Publisher, ctx: &mut TxContext): (MembershipPolicy<T>, MembershipPolicyCap<T>){
  assert!(package::from_package<T>(pub), 0);

  let id = object::new(ctx);
  let policy_id = id.to_inner();
  // event::emit(MembershipPolicyCreated<T> { id: policy_id });
  (
      MembershipPolicy<T> { 
        id, 
        // rules: vec_set::empty(), 
        balance: balance::zero(),
        version: 0,
        },
      MembershipPolicyCap<T> { id: object::new(ctx), policy_id },
  )
}

// 앗!!!! layer도 다 주면 안 되겠네!! special layer가 있을 테니깐
// public fun create_bases<T: key>(
//     self: &MembershipPolicy<T>,
//     cap: &MembershipPolicyCap<T>,
//     quantity : u64,
//     ctx: &mut TxContext,
// ) : (CreateRequest<T>) {
//   assert!(object::id(self) == cap.policy_id, ENotOwner);

//   let request = CreateRequest<T>{};

//   (request)
// }
// ===================================== User Functions
public macro fun convert_phase1_to_phase2<$T: key, $R: drop>($base: &mut $T, $f: |&mut TxContext| -> $T) {
    // let mut v = $v;
    // v.reverse();
    // v.length().do!(|_| $f(v.pop_back()));
    // v.destroy_empty();


    // 믿지 말자
    // dynamic_field::add($base, b"name".to_string(), b"value".to_string());
}

// public macro fun equip_base_bag<$T: key, $R: drop>($base: &mut $T, $f: |$T| -> $R) {
    // let mut v = $v;
    // v.reverse();
    // v.length().do!(|_| $f(v.pop_back()));
    // v.destroy_empty();


    // 믿지 말자
    // dynamic_field::add($base, b"name".to_string(), b"value".to_string());
// }

public fun confirm<T: key>(
  policy: &mut MembershipPolicy<T>,
  condition: &Condition<T>,
  collector: &mut TicketCollector<T>,
  base: &mut T,
  // base: &mut UID,
) {

}

// 티켓 자판가??
public fun add_ticket_to_base<T: key, Ticket: drop>(
    policy: &mut MembershipPolicy<T>,
    // cap: &MembershipPolicyCap<T>,
    condition: &Condition<T>,
    _: Ticket,
    order: u64,
    // cfg: Config,
) {
    // assert!(object::id(policy) == cap.policy_id, ENotOwner);
    // assert!(!has_layer<T, LayerType, Config>(policy), ERuleAlreadySet);

    // dynamic_field::add<LayerKey<T, LayerType, Config>, LayerConfig<LayerType, Config>>( &mut policy.id, LayerKey<T, LayerType, Config> {}, LayerConfig{order, `type`, cfg});
}

// 어떻게 base에 layer를 넣지? uid 접근 안 돼서 dynamic field 못 하는데..
// UID를 받으면 되긴 하는데... 이건 move에서 어떤 function을 제공해야 하잖아??
// 즉, 이 함수를 실행하려면 T 타입이 있는 모듈에서 move code로 밖에 사용할 수 없잖아?
public fun add_layer_to_base<T: key, LayerType: store + drop, Config: store + drop>(
    policy: &mut MembershipPolicy<T>,
    // cap: &MembershipPolicyCap<T>,
    // base: &mut UID,
    base: &mut T,
    condition: &Condition<T>,
    _: LayerType,
    order: u64,
    cfg: Config,
) {
    // assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_layer<T, LayerType, Config>(policy), ERuleAlreadySet);

    // dynamic_field::add(base, b"name".to_string(), b"value".to_string());

    // dynamic_field::add<LayerKey<T, LayerType, Config>, LayerConfig<LayerType, Config>>( &mut policy.id, LayerKey<T, LayerType, Config> {}, LayerConfig{order, `type`, cfg});
}

// public fun enter_the_ecosystem_as_a_member<T: key>(policy: &mut MembershipPolicy<T>, request: MembershipRequest<T>, ctx: &mut TxContext){

// }

// ===================================== Admin Functions

public fun add_ticket<T: key, Ticket: drop, Config: store + drop>(
    _: Ticket,
    policy: &mut MembershipPolicy<T>,
    cap: &MembershipPolicyCap<T>,
    cfg: Config,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    // assert!(!has_rule<T, Rule>(policy), ERuleAlreadySet);
    // df::add(&mut policy.id, RuleKey<Rule> {}, cfg);
    // policy.rules.insert(type_name::get<Rule>())
}

public fun add_base_type<T: key, Config: store + drop>(
    policy: &mut MembershipPolicy<T>,
    // cap: &MembershipPolicyCap<T>,
    base: &mut T,
    // `type`: LayerType,
    // order: u64,
    img_url: String,
    cfg: Config,
) {
    // assert!(object::id(policy) == cap.policy_id, ENotOwner);
    // assert!(!has_layer<T, LayerType, Config>(policy), ERuleAlreadySet);

    // dynamic_field::add<BaseKey<T, Config>, BaseConfig<T, Config>>( &mut policy.id, BaseKey<T, Config> {}, BaseConfig{img_url, cfg});
    dynamic_field::add<BaseKey<T, Config>, BaseConfig<T, Config>>( &mut policy.id, BaseKey<T, Config> {}, BaseConfig{img_url, cfg});
}

public fun add_layer_type<T: key, LayerType: store + drop, Config: store + drop>(
    policy: &mut MembershipPolicy<T>,
    cap: &MembershipPolicyCap<T>,
    `type`: LayerType,
    order: u64,
    cfg: Config,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_layer<T, LayerType, Config>(policy), ERuleAlreadySet);

    dynamic_field::add<LayerKey<T, LayerType, Config>, LayerConfig<LayerType, Config>>( &mut policy.id, LayerKey<T, LayerType, Config> {}, LayerConfig{order, `type`, cfg});
    policy.update_version_policy(cap);
}

public fun add_item_type<T: key, LayerType: store + drop, Config: store + drop>(
    policy: &mut MembershipPolicy<T>,
    cap: &MembershipPolicyCap<T>,
    `type`: LayerType,
    item_type: String,
    img_url: String,
    cfg: Config,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_item<T, LayerType, Config>(policy, item_type), ERuleAlreadySet);

    let item_config = ItemConfig<T, LayerType, Config>{`type`, item_type, img_url, cfg};
    dynamic_field::add(&mut policy.id, ItemKey<T, LayerType, Config> {item_type}, item_config);
    policy.update_version_policy(cap);
}

public fun add_property_type<T: key, PropertyType: store + drop, Config: store + drop>(
    policy: &mut MembershipPolicy<T>,
    cap: &MembershipPolicyCap<T>,
    `type`: PropertyType,
    min: u64,
    max: u64,
    cfg: Config,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    assert!(!has_property<T, PropertyType, Config>(policy), ERuleAlreadySet);

    let property_config = PropertyConfig<T, PropertyType, Config>{`type`, cfg, min, max};
    dynamic_field::add(&mut policy.id, PropertyKey<T, PropertyType, Config> {}, property_config);
    policy.update_version_policy(cap);
}

public fun add_rule<T: key, Rule: drop, CustomConfig: store + drop>(
    policy: &mut MembershipPolicy<T>,
    cap: &MembershipPolicyCap<T>,
    _: Rule,
    cfg: CustomConfig,
) {
    assert!(object::id(policy) == cap.policy_id, ENotOwner);
    // assert!(!has_rule<T, Rule>(policy), ERuleAlreadySet);
    // dynamic_field::add(&mut policy.id, RuleKey<T, Rule> {}, cfg);
    // policy.rules.insert(type_name::get<RuleKey<T, Rule>>())
    policy.update_version_policy(cap);
}

// -------------------------- Create Functions


// ===================================== Public Functions
public fun has_layer<T: key, LayerType: store + drop, Config: store + drop>(policy: &MembershipPolicy<T>): bool {
  dynamic_field::exists_(&policy.id, LayerKey<T, LayerType, Config> {})
}
public fun has_item<T: key, LayerType: store + drop, Config: store + drop>(policy: &MembershipPolicy<T>, item_type: String): bool {
  dynamic_object_field::exists_(&policy.id, ItemKey<T, LayerType, Config> {item_type})
}
public fun has_property<T: key, PropertyType: store + drop, Config: store + drop>(policy: &MembershipPolicy<T>): bool {
  dynamic_field::exists_(&policy.id, PropertyKey<T, PropertyType, Config> {})
}
// public fun has_rule<T: key, Rule: drop>(policy: &MembershipPolicy<T>): bool {
//   dynamic_field::exists_(&policy.id, RuleKey<T, Rule> {})
// }

// ============================= Public Package Functions
public (package) fun update_version_policy<T: key>(policy: &mut MembershipPolicy<T>, cap: &MembershipPolicyCap<T>) {
  policy.version = policy.version + 1;
}
public (package) fun get_struct_name(self: TypeName): String {
    let ascii_colon: u8 = 58;
    let ascii_less_than: u8 = 60;
    let ascii_greater_than: u8 = 62;

    let mut str_bytes = self.into_string().into_bytes();
    let mut struct_name = vector<u8>[];
    loop {
        let char = str_bytes.pop_back<u8>();
        if (char == ascii_less_than || char == ascii_greater_than) {
          continue
        }else if (char != ascii_colon ) {
          struct_name.push_back(char);
        } else {
            break
        }
    };

    struct_name.reverse();
    struct_name.to_string()
}