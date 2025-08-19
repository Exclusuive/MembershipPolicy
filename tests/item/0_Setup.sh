#!/bin/bash

# 🧪 패키지 ID와 모듈명
PACKAGE_ID=0xa5be14205f1e05332841c02bce7fc32022a8d2b58bc86a3526b86d6e754cc8d8
MODULE_NAME=community
RECEIVER=0xd5726993ab71c2daa0309ecf30c4c40b59b80479b69ff95336a88ff60f9596aa

# 🎯 커뮤니티 생성
echo "🚀 Executing create_community..."
sui client call  --package $PACKAGE_ID --module $MODULE_NAME --function create_community

echo "✅ Community created."
