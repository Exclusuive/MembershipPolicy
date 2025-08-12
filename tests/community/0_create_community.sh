#!/bin/bash

# 🧪 패키지 ID와 모듈명
PACKAGE_ID=0xd07e55fc791154a485f16aff2b84ce7003a274b5b170f727f29ea941cae56abc
MODULE_NAME=community
RECEIVER=0xd5726993ab71c2daa0309ecf30c4c40b59b80479b69ff95336a88ff60f9596aa

# 🎯 커뮤니티 생성
echo "🚀 Executing create_community..."
sui client call  --package $PACKAGE_ID --module $MODULE_NAME --function create_community

echo "✅ Community created."
