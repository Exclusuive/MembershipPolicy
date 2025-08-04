#!/bin/bash

# 🧪 패키지 ID와 모듈명
PACKAGE_ID=0x1b1c4acb54d924f4be6dec503d26d505ae1f0764ecfdbc05c1b44fff1e009e9c
COMMUNITY_ID=0xed032c840e0f8e47b93cd9d70459ecfa5e4fc5f76dc622e5cea36688465d9e2c
MEMBERSHIP_ID=0xed032c840e0f8e47b93cd9d70459ecfa5e4fc5f76dc622e5cea36688465d9e2c
MODULE_COMMUNITY=community
MODULE_MEMBERSHIP=membership
RECEIVER=0xd5726993ab71c2daa0309ecf30c4c40b59b80479b69ff95336a88ff60f9596aa

# 🎯 커뮤니티 생성 및 멤버십 추가
echo "🚀 Executing new_community and new_membership_type..."
sui client ptb \
  --move-call $PACKAGE_ID::$MODULE_MEMBERSHIP::equip_item_to_membership @$COMMUNITY_ID @$MEMBERSHIP_ID  \
  --assign membership \
  --move-call $PACKAGE_ID::$MODULE_MEMBERSHIP::equip_item_to_membership @$COMMUNITY_ID @$MEMBERSHIP_ID  \
  --assign membership \

echo "✅ Community created."