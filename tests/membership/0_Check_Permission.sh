#!/bin/bash

# 🧪 패키지 ID와 모듈명
COMMUNITY_MODULE=community
MEMBERSHIP_MODULE=membership
PACKAGE_ID=0xd07e55fc791154a485f16aff2b84ce7003a274b5b170f727f29ea941cae56abc
MODULE_NAME=community
RECEIVER=0xd5726993ab71c2daa0309ecf30c4c40b59b80479b69ff95336a88ff60f9596aa
COMMUNITY=0x2465de74a2114a1d9981f422ec79acb6585edb58477e144e095f20fccb18666f
COMMUNITY_CAP=0x815c9df2274580f20f12fcb18b3a45f1f3999174cc0d773293843653a6a8d3b0

# 🎯 커뮤니티 생성
echo "🚀 Testing Membership"

echo "🚀 Register membership type without permission (Should fail)"
sui client call  --package $PACKAGE_ID --module $MEMBERSHIP_MODULE --function new_membership_type --args $COMMUNITY '"TEST"'

echo "🚀 Grant permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $COMMUNITY_MODULE --function grant_permission --args $COMMUNITY $COMMUNITY_CAP '"membership_manager"' $RECEIVER


echo "🚀 Register config type with permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $MEMBERSHIP_MODULE --function new_membership_type --args $COMMUNITY '"TEST"' 

echo "🚀 Revoke permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $COMMUNITY_MODULE --function revoke_permission --args $COMMUNITY $COMMUNITY_CAP '"membership_manager"' $RECEIVER

echo "🚀 New membership without permission (Should fail)"
sui client call  --package $PACKAGE_ID --module $MEMBERSHIP_MODULE --function new_membership --args $COMMUNITY '"TEST"' '"TEST_IMAGE_URL"'

echo "🚀 Grant permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $COMMUNITY_MODULE --function grant_permission --args $COMMUNITY $COMMUNITY_CAP '"membership_manager"' $RECEIVER

echo "🚀 New membership with permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $MEMBERSHIP_MODULE --function mint_membership --args $COMMUNITY '"TEST"' '"TEST_IMAGE_URL"' $RECEIVER


echo "✅ Check_permission tested."
