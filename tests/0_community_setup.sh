#!/bin/bash

# 🧪 패키지 ID와 모듈명
PACKAGE_ID=0xf996d00ef306d4d6d5b60c882b391a325580db83542bd7fbc4de73ce12b8e1dd
MODULE_NAME=community
RECEIVER=0xd5726993ab71c2daa0309ecf30c4c40b59b80479b69ff95336a88ff60f9596aa

# 🎯 커뮤니티 생성 및 멤버십 추가
echo "🚀 Executing new_community and new_membership_type..."
sui client ptb \
  --move-call $PACKAGE_ID::$MODULE_NAME::new_community \
  --assign community \
  --move-call $PACKAGE_ID::$MODULE_NAME::grant_permission community.0 community.1 '"membership"' @$RECEIVER \
  --move-call $PACKAGE_ID::$MODULE_NAME::grant_permission community.0 community.1 '"item"' @$RECEIVER \
  --move-call $PACKAGE_ID::$MODULE_NAME::grant_permission community.0 community.1 '"ticket"' @$RECEIVER \
  --move-call $PACKAGE_ID::$MODULE_NAME::register_membership_type community.0 community.1 '"VIP"' \
  --move-call $PACKAGE_ID::$MODULE_NAME::register_part_type community.0 community.1 '"VIP"' '"TEST"' \
  --move-call $PACKAGE_ID::$MODULE_NAME::register_item_type community.0 community.1 '"VIP"' '"TEST"' '"TEST_ITEM_1"' '"https://example.com/image.png"' \
  --move-call $PACKAGE_ID::$MODULE_NAME::register_item_type community.0 community.1 '"VIP"' '"TEST"' '"TEST_ITEM_2"' '"https://example.com/image.png"' \
  --move-call $PACKAGE_ID::$MODULE_NAME::register_attribute_type community.0 community.1 '"TEST"' \
  --move-call $PACKAGE_ID::$MODULE_NAME::register_ticket_type community.0 community.1 '"TEST"' \
  --move-call $PACKAGE_ID::$MODULE_NAME::register_config_type community.0 '"TEST"' '"TEST_CONFIG"' \
  --move-call $PACKAGE_ID::$MODULE_NAME::update_config_type community.0 '"TEST"' '"TEST_CONFIG_2"' \
  --transfer-objects "["community.0", "community.1"]" @$RECEIVER \

echo "✅ Community created."

#   --move-call $PACKAGE_ID::$MODULE_NAME::grant_permission community.0 community.1 '"membership"' @$RECEIVER \
#   --move-call $PACKAGE_ID::$MODULE_NAME::revoke_permission community.0 community.1 '"membership"' @$RECEIVER \