#!/bin/bash

# 🧪 패키지 ID와 모듈명
PACKAGE_ID=0x0b38e39e88cbd0bcf1118a7d584793923cbf272c41c7ec4e7a24b2e43079084f
COMMUNITY_MODULE=community
MEMBERSHIP_MODULE=exclusuive_membership
MARKET_MODULE=payment
REWARD_MODULE=reward
MARKET=0x052b1f15f9a87ddcac27fb8617757539356229c2023384be77de8558edfd9d05
COMMUNITY=0x0506a3546577ee218530eab0747f211edb3c291947d16bf05e3757f468a06f11
COMMUNITY_CAP=0xa3588bc0aa97c4dda5a15032a9aa611f01e9efa013dde5b93c6a5eb1386ddf78
RECEIVER=0xd6bd698c63896fc0fc0656d56ca7c6248e278a2a00c7a56164a6f60a2e6cacc4
SLUSH=0x013aa8e195bdfac65bf0bb126da30426ffaedb90b95a8edd83a8aff4cea6a2bb
MEMBERSHIP=0xac814b6da4b270dd340c7ecc260649227433683504a23330789ef617de4a4b4a

🎯 멤버십 생성

# echo "Payment without Membership"
# sui client ptb \
#   --split-coins gas "[1000]" \
#   --assign SUI_COIN \
#   --move-call $PACKAGE_ID::$MARKET_MODULE::process_payment_without_membership "<0x2::sui::SUI>" @$MARKET SUI_COIN 1000 \
#   --transfer-objects "["SUI_COIN"]" @$RECEIVER

# echo "Payment with Membership"
# sui client ptb \
#   --split-coins gas "[1000]" \
#   --assign SUI_COIN \
#   --move-call $PACKAGE_ID::$MARKET_MODULE::process_payment_with_membership "<0x2::sui::SUI>" @$COMMUNITY @$MARKET SUI_COIN 1000 @$MEMBERSHIP \
#   --transfer-objects "["SUI_COIN"]" @$RECEIVER


# echo "Payment with Membership"
# sui client call  --package $PACKAGE_ID --module $MARKET_MODULE --function process_payment_with_membership --args $MARKET $MEMBERSHIP $SUI_COIN $RECEIVER 100

# echo "Withdraw"
# sui client call  --package $PACKAGE_ID --module $MARKET_MODULE --function withdraw --args $MARKET $COMMUNITY_CAP $RECEIVER


echo "✅ Market created."
