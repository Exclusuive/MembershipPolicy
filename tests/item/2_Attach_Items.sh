#!/bin/bash

# 🧪 패키지 ID와 모듈명
PACKAGE_ID=0x837dfe7df80b626f25edf00d2b4f5e3dbe8a6aba0f34f1b2201db1981f54771f
ITEM_MODULE=item
COMMUNITY_MODULE=community
MEMBERSHIP_MODULE=membership
RECEIVER=0xd5726993ab71c2daa0309ecf30c4c40b59b80479b69ff95336a88ff60f9596aa
COMMUNITY=0x5f5b4abbd7ee5182de389733e532783a36a2dee83dd57820f6e009311c836b7e
COMMUNITY_CAP=0x164102b943688c8dc7d52ae578473f4e5c4429cc070ec4cfa7660217f1e91f00


# echo "🚀 Grant permission (Should pass)"
# sui client call  --package $PACKAGE_ID --module $COMMUNITY_MODULE --function grant_permission --args $COMMUNITY $COMMUNITY_CAP '"membership_manager"' $RECEIVER

# echo "🚀 Grant permission (Should pass)"
# sui client call  --package $PACKAGE_ID --module $COMMUNITY_MODULE --function grant_permission --args $COMMUNITY $COMMUNITY_CAP '"item_manager"' $RECEIVER


# echo "🚀 Register slot type with permission (Should pass)"
# sui client call  --package $PACKAGE_ID --module $ITEM_MODULE --function new_slot_type --args $COMMUNITY '"TEST"' '"TEST_SLOT"'


# echo "🚀 Register trait type without permission (Should pass)"
# sui client call  --package $PACKAGE_ID --module $ITEM_MODULE --function new_trait_type --args $COMMUNITY '"TEST"' '"TEST_TRAIT"'


# echo "🚀 Register item type with permission (Should pass)"
# sui client call  --package $PACKAGE_ID --module $ITEM_MODULE --function new_item_type --args $COMMUNITY '"TEST"' '"TEST_SLOT"' '"TEST_ITEM"' '"TEST_IMAGE_URL"'


# echo "🚀 New item (Should pass)"
# sui client ptb \
#   --move-call $PACKAGE_ID::$MEMBERSHIP_MODULE::new_membership_type @$COMMUNITY '"TEST"' \
#   --move-call $PACKAGE_ID::$MEMBERSHIP_MODULE::new_membership @$COMMUNITY '"TEST"' '"TEST_IMAGE_URL"' \
#   --assign MEMBERSHIP \
#   --move-call $PACKAGE_ID::item::new_item @$COMMUNITY '"TEST"' '"TEST_SLOT"' '"TEST_ITEM"' \
#   --assign ITEM \
#   --move-call $PACKAGE_ID::item::new_trait @$COMMUNITY '"TEST"' '"TEST_TRAIT"' 16 \
#   --assign TRAIT \
#   --move-call $PACKAGE_ID::item::attach_trait_to_item @$COMMUNITY ITEM TRAIT \
#   --move-call $PACKAGE_ID::item::equip_item_to_membership @$COMMUNITY MEMBERSHIP ITEM \
#   --transfer-objects "["MEMBERSHIP"]" @$RECEIVER



echo "🚀 Unequip item from membership (Should pass)"

sui client call  --package $PACKAGE_ID --module $ITEM_MODULE --function unequip_item_from_membership --args $COMMUNITY "0x99a47f4e182bea711155881830b4be9f563c0dd04ccb0e90a8ba077cee85ce64" '"TEST_SLOT"'