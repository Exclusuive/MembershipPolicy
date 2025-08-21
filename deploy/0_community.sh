#!/bin/bash

# 🧪 패키지 ID와 모듈명
PACKAGE_ID=0x0b38e39e88cbd0bcf1118a7d584793923cbf272c41c7ec4e7a24b2e43079084f
MODULE_NAME=community
RECEIVER=0xd5726993ab71c2daa0309ecf30c4c40b59b80479b69ff95336a88ff60f9596aa

# 🎯 커뮤니티 생성
echo "🚀 Executing create_community..."
sui client call  --package $PACKAGE_ID --module $MODULE_NAME --function create_community

echo "✅ Community created."
