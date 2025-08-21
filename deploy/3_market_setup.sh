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

🎯 멤버십 생성

echo "New Ticket Type"
sui client call  --package $PACKAGE_ID --module $REWARD_MODULE --function new_ticket_type --args $COMMUNITY '"TEST_TICKET"'

echo "New Membership Policy"
sui client call  --package $PACKAGE_ID --module $MARKET_MODULE --function new_membership_policy --args $COMMUNITY $MARKET '"TEST"' 1000 '"TEST_TICKET"' 5 true



echo "✅ Market created."
