#!/bin/bash

# 🧪 패키지 ID와 모듈명
PACKAGE_ID=0xb5e7b979e1caffb00bc6a8dfcbdafa230f3b31a4aa54377a26d7739a255c0a34
ITEM_MODULE=item
COMMUNITY_MODULE=community
RECEIVER=0x013aa8e195bdfac65bf0bb126da30426ffaedb90b95a8edd83a8aff4cea6a2bb
COMMUNITY=0xaf550af908b1acb9496d29d27b2985a4614a41c60b27e6d8d0ee8c85aa91a8eb
COMMUNITY_CAP=0x3f2075b6bbeeba08837773ad4ebae52893bd3609acd050b2b2327f3da342e2ab
MEMBERSHIP_MODULE=membership


# echo "🚀 Grant permission (Should pass)"
# sui client call  --package $PACKAGE_ID --module $COMMUNITY_MODULE --function grant_permission --type-args $PACKAGE_ID::$COMMUNITY_MODULE::MembershipManager --args $COMMUNITY $COMMUNITY_CAP $RECEIVER

# echo "🚀 Grant permission (Should pass)"
# sui client call  --package $PACKAGE_ID --module $COMMUNITY_MODULE --function grant_permission --type-args $PACKAGE_ID::$COMMUNITY_MODULE::ItemManager --args $COMMUNITY $COMMUNITY_CAP $RECEIVER


# echo "🚀 Register slot type with permission (Should pass)"
# sui client call  --package $PACKAGE_ID --module $ITEM_MODULE --function new_slot_type --args $COMMUNITY '"TEST"' '"TEST_SLOT"'


# echo "🚀 Register trait type without permission (Should pass)"
# sui client call  --package $PACKAGE_ID --module $ITEM_MODULE --function new_trait_type --args $COMMUNITY '"TEST"' '"TEST_TRAIT"'


# echo "🚀 Register item type with permission (Should pass)"
# sui client call  --package $PACKAGE_ID --module $ITEM_MODULE --function new_item_type --args $COMMUNITY '"TEST"' '"TEST_SLOT"' '"TEST_ITEM"' '"TEST_IMAGE_URL"'


echo "🚀 New item (Should pass)"
sui client ptb \
  --move-call $PACKAGE_ID::$MEMBERSHIP_MODULE::new_membership @$COMMUNITY '"TEST"' '"TEST_IMAGE_URL"' \
  --assign MEMBERSHIP \
  --move-call $PACKAGE_ID::item::new_item @$COMMUNITY '"TEST"' '"TEST_SLOT"' '"TEST_ITEM"' \
  --assign ITEM \
  --move-call $PACKAGE_ID::item::new_trait @$COMMUNITY '"TEST"' '"TEST_TRAIT"' 16 \
  --assign TRAIT \
  --move-call $PACKAGE_ID::item::attach_trait_to_item @$COMMUNITY ITEM TRAIT \
  --transfer-objects "["MEMBERSHIP", "ITEM"]" @$RECEIVER



echo "🚀 Unequip item from membership (Should pass)"
  # --move-call $PACKAGE_ID::$MEMBERSHIP_MODULE::new_membership_type @$COMMUNITY '"TEST"' \

#   --move-call $PACKAGE_ID::item::equip_item_to_membership @$COMMUNITY MEMBERSHIP ITEM \
# sui client call  --package $PACKAGE_ID --module $ITEM_MODULE --function unequip_item_from_membership --args $COMMUNITY "0x68f5b81b855557571a906e237cdf54b6323dcedf3e98a62a2dd007a24ca4fc0a" '"TEST_SLOT"'