#!/bin/bash

# 🧪 패키지 ID와 모듈명
COMMUNITY_MODULE=community
MEMBERSHIP_MODULE=membership
PACKAGE_ID=0xc074172d84e2a9754e2a3bcc65f2e18f0539510f28e8538114338c73422a5e6f
MODULE_NAME=community
RECEIVER=0xd5726993ab71c2daa0309ecf30c4c40b59b80479b69ff95336a88ff60f9596aa
COMMUNITY=0x491f598798ba32035cb5ed3cc2f762560a2877f79a8f75965d78b82d7a671bf8
COMMUNITY_CAP=0x1f5836bab40771a93f5db4b87e786d72eb7361f93df5de500d008b78dfea4f1d

# 🎯 커뮤니티 생성
echo "🚀 Testing Membership"

echo "🚀 Grant permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $COMMUNITY_MODULE --function grant_permission --type-args $PACKAGE_ID::$COMMUNITY_MODULE::MembershipManager --args $COMMUNITY $COMMUNITY_CAP $RECEIVER

echo "🚀 Register config type with permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $MEMBERSHIP_MODULE --function new_membership_type --args $COMMUNITY '"Season1"' 1

echo "🚀 Register config type with permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $MEMBERSHIP_MODULE --function new_membership_type --args $COMMUNITY '"Season2"' 1

echo "🚀 Register config type with permission (Should pass)"
sui client call  --package $PACKAGE_ID --module $MEMBERSHIP_MODULE --function new_membership_type --args $COMMUNITY '"Athens"' 1


echo "✅ Check_permission tested."
