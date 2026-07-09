#!/bin/bash
# Хэш состава SDK: списки исходников/ресурсов + содержимое podspec-ов.
# Единый источник истины для Podfile (post_install) и build-фазы "[Kvell] SDK Sync Check".
set -euo pipefail
export LC_ALL=C

cd "$(dirname "$0")/.."

{
  find sdk/Sources networking/source DevKit/Sources -type f -name "*.swift" 2>/dev/null
  find sdk/Resources -type f ! -name ".*" 2>/dev/null
  cat Kvell.podspec KvellNetworking.podspec DevKit/KvellDevKit.podspec 2>/dev/null
} | sort | shasum -a 1 | cut -d' ' -f1
