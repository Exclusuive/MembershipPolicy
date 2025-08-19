#!/bin/bash

# 🧪 패키지 ID와 모듈명
PACKAGE_ID=0xc074172d84e2a9754e2a3bcc65f2e18f0539510f28e8538114338c73422a5e6f
MODULE_NAME=community
RECEIVER=0xd5726993ab71c2daa0309ecf30c4c40b59b80479b69ff95336a88ff60f9596aa

# 🎯 커뮤니티 생성
echo "🚀 Executing create_community..."
sui client call  --package $PACKAGE_ID --module $MODULE_NAME --function create_community

echo "✅ Community created."
