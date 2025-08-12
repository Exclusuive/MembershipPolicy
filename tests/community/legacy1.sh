#!/bin/bash

# 🧪 패키지 ID와 모듈명
PACKAGE_ID=0xf996d00ef306d4d6d5b60c882b391a325580db83542bd7fbc4de73ce12b8e1dd
COMMUNITY_ID=0xeded202f29fff9d333f3d59650eb433c2b0f2cc70f88b2c359ee4795878ee3b2
MODULE_COMMUNITY=community
MODULE_MEMBERSHIP=membership
RECEIVER=0xd5726993ab71c2daa0309ecf30c4c40b59b80479b69ff95336a88ff60f9596aa

# 🎯 커뮤니티 생성 및 멤버십 추가
echo "🚀 Executing new_community and new_membership_type..."
sui client ptb \
  --move-call $PACKAGE_ID::$MODULE_MEMBERSHIP::new_membership @$COMMUNITY_ID '"VIP"' '"https://example.com/image.png"' \
  --assign membership \
  --move-call $PACKAGE_ID::$MODULE_COMMUNITY::new_item @$COMMUNITY_ID '"TEST_ITEM_1"' \
  --assign item_1 \
  --move-call $PACKAGE_ID::$MODULE_COMMUNITY::new_item @$COMMUNITY_ID '"TEST_ITEM_2"' \
  --assign item_2 \
  --move-call $PACKAGE_ID::$MODULE_COMMUNITY::new_ticket @$COMMUNITY_ID '"TEST"' \
  --assign ticket \
  --move-call $PACKAGE_ID::$MODULE_COMMUNITY::new_attribute @$COMMUNITY_ID '"TEST"' 100 \
  --assign attribute \
  --move-call $PACKAGE_ID::$MODULE_COMMUNITY::attach_attribute item_1 attribute \
  --move-call $PACKAGE_ID::$MODULE_MEMBERSHIP::equip_item_to_membership @$COMMUNITY_ID membership item_1 \
  --move-call $PACKAGE_ID::$MODULE_MEMBERSHIP::equip_item_to_membership @$COMMUNITY_ID membership item_2 \
  --transfer-objects "["ticket", "membership"]" @$RECEIVER \

echo "✅ Community created."