#!/bin/bash

# 🧪 패키지 ID와 모듈명
PACKAGE_ID=0x11529eb37254d54d3903714d63daa655559bbf5ddae2c73fd35cdaed7e1e863a
ITEM_MODULE=item
COMMUNITY_MODULE=community
RECEIVER=0xd5726993ab71c2daa0309ecf30c4c40b59b80479b69ff95336a88ff60f9596aa
COMMUNITY=0xdfa768536bcda624c6daa0224806a6b8f60f983705664484819d5fd0e9afe865
COMMUNITY_CAP=0xbb564349cf7aa11a4e904478cfab3f09b519ce6b2651ddcdbe612276d523a412

# 🎯 커뮤니티 생성
echo "🚀 Testing Community"

echo "🚀 Update trait type with permission (Should fail)"
sui client call  --package $PACKAGE_ID --module $ITEM_MODULE --function new_slot_type --args $COMMUNITY '"TEST"' '"TEST_SLOT"'


echo "🚀 Register trait type without permission (Should fail)"
sui client call  --package $PACKAGE_ID --module $ITEM_MODULE --function new_trait_type --args $COMMUNITY '"TEST"' '"TEST_TRAIT"'


echo "🚀 Register item type with permission (Should fail)"
sui client call  --package $PACKAGE_ID --module $ITEM_MODULE --function new_item_type --args $COMMUNITY '"TEST"' '"TEST_SLOT"' '"TEST_ITEM"' '"TEST_IMAGE_URL"'

echo "🚀 Grant permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $COMMUNITY_MODULE --function grant_permission --args $COMMUNITY $COMMUNITY_CAP '"item_manager"' $RECEIVER



echo "🚀 Update trait type with permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $ITEM_MODULE --function new_slot_type --args $COMMUNITY '"TEST"' '"TEST_SLOT"'


echo "🚀 Register trait type without permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $ITEM_MODULE --function new_trait_type --args $COMMUNITY '"TEST"' '"TEST_TRAIT"'


echo "🚀 Register item type with permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $ITEM_MODULE --function new_item_type --args $COMMUNITY '"TEST"' '"TEST_SLOT"' '"TEST_ITEM"' '"TEST_IMAGE_URL"'



echo "✅ Check_permission tested."
