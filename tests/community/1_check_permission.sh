#!/bin/bash

# 🧪 패키지 ID와 모듈명
PACKAGE_ID=0xb5e7b979e1caffb00bc6a8dfcbdafa230f3b31a4aa54377a26d7739a255c0a34
MODULE_NAME=community
RECEIVER=0xd5726993ab71c2daa0309ecf30c4c40b59b80479b69ff95336a88ff60f9596aa
COMMUNITY=0xaf550af908b1acb9496d29d27b2985a4614a41c60b27e6d8d0ee8c85aa91a8eb
COMMUNITY_CAP=0x3f2075b6bbeeba08837773ad4ebae52893bd3609acd050b2b2327f3da342e2ab

# 🎯 커뮤니티 생성
echo "🚀 Testing Community"

echo "🚀 Register config type without permission (Should fail)"
sui client call  --package $PACKAGE_ID --module $MODULE_NAME --function new_config_type --args $COMMUNITY '"TEST"' '"TEST_CONFIG"'

echo "🚀 Grant permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $MODULE_NAME --function grant_permission --type-args $PACKAGE_ID::$MODULE_NAME::CommunityManager --args $COMMUNITY $COMMUNITY_CAP $RECEIVER


echo "🚀 Register config type with permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $MODULE_NAME --function new_config_type --args $COMMUNITY '"TEST"' '"TEST_CONFIG"'

echo "🚀 Revoke permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $MODULE_NAME --function revoke_permission --type-args $PACKAGE_ID::$MODULE_NAME::CommunityManager --args $COMMUNITY $COMMUNITY_CAP $RECEIVER

echo "🚀 Update config type without permission (Should fail)"
sui client call  --package $PACKAGE_ID --module $MODULE_NAME --function update_config_type --args $COMMUNITY '"TEST"' '"TEST_CONFIG_2"'

echo "🚀 Grant permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $MODULE_NAME --function grant_permission --type-args $PACKAGE_ID::$MODULE_NAME::CommunityManager --args $COMMUNITY $COMMUNITY_CAP $RECEIVER

echo "🚀 Update config type with permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $MODULE_NAME --function update_config_type --args $COMMUNITY '"TEST"' '"TEST_CONFIG_2"'


echo "✅ Check_permission tested."
