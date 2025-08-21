#!/bin/bash

# 🧪 패키지 ID와 모듈명
PACKAGE_ID=0x0b38e39e88cbd0bcf1118a7d584793923cbf272c41c7ec4e7a24b2e43079084f
COMMUNITY_MODULE=community
MEMBERSHIP_MODULE=exclusuive_membership
COMMUNITY=0x0506a3546577ee218530eab0747f211edb3c291947d16bf05e3757f468a06f11
COMMUNITY_CAP=0xa3588bc0aa97c4dda5a15032a9aa611f01e9efa013dde5b93c6a5eb1386ddf78
RECEIVER=0xd6bd698c63896fc0fc0656d56ca7c6248e278a2a00c7a56164a6f60a2e6cacc4
SLUSH=0x013aa8e195bdfac65bf0bb126da30426ffaedb90b95a8edd83a8aff4cea6a2bb

🎯 멤버십 생성

# echo "🚀 Grant permission (Should pass)"
# sui client call  --package $PACKAGE_ID --module $COMMUNITY_MODULE --function grant_permission --type-args $PACKAGE_ID::$COMMUNITY_MODULE::MembershipManager --args $COMMUNITY $COMMUNITY_CAP $RECEIVER

# echo "🚀 Register config type with permission (Should pass)"
# sui client call  --package $PACKAGE_ID --module $MEMBERSHIP_MODULE --function new_membership_type --args $COMMUNITY '"TEST"' '"TEST_DESCRIPTION"' true true

sui client ptb \
  --move-call $PACKAGE_ID::$MEMBERSHIP_MODULE::new_membership @$COMMUNITY '"TEST"' '"https://ezesepaxcbbzvjjzivwe.supabase.co/storage/v1/object/public/exclusuive/collection/Blockthon2025.png"' \
  --assign MEMBERSHIP \
  --move-call $PACKAGE_ID::$MEMBERSHIP_MODULE::transfer MEMBERSHIP @$RECEIVER


echo "✅ Community created."
