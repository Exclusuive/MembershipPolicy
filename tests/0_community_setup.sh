#!/bin/bash

# 🧪 패키지 ID와 모듈명
PACKAGE_ID=0xa8608944300bbb93d7603f9683dfc6978bd8641166e9b9e4c34b7b1dfcf39b8c
MODULE_NAME=community
RECEIVER=0xd5726993ab71c2daa0309ecf30c4c40b59b80479b69ff95336a88ff60f9596aa

# 🎯 커뮤니티 생성 및 멤버십 추가
echo "🚀 Executing new_community and new_membership_type..."
sui client ptb \
  --move-call $PACKAGE_ID::$MODULE_NAME::new_community \
  --assign community \
  --move-call $PACKAGE_ID::$MODULE_NAME::register_membership_type community  '"VIP"' \
  --move-call $PACKAGE_ID::$MODULE_NAME::register_part_type community  '"VIP"' '"TEST"' \
  --move-call $PACKAGE_ID::$MODULE_NAME::register_item_type community  '"VIP"' '"TEST"' '"TEST_ITEM_1"' '"https://example.com/image.png"' \
  --move-call $PACKAGE_ID::$MODULE_NAME::register_item_type community  '"VIP"' '"TEST"' '"TEST_ITEM_2"' '"https://example.com/image.png"' \
  --move-call $PACKAGE_ID::$MODULE_NAME::register_attribute_type community  '"TEST"' \
  --move-call $PACKAGE_ID::$MODULE_NAME::register_ticket_type community  '"TEST"' \
  --move-call $PACKAGE_ID::$MODULE_NAME::register_config_type community  '"TEST"' '"TEST_CONFIG"' \
  --move-call $PACKAGE_ID::$MODULE_NAME::update_config_type community  '"TEST"' '"TEST_CONFIG_2"' \
  --transfer-objects ["community"] @$RECEIVER \

echo "✅ Community created."