#!/bin/bash
# Актуализирует демо после изменений SDK: dev pods подхватывают новые/удалённые
# файлы и ресурсы только после pod install.
set -euo pipefail
cd "$(dirname "$0")"

# CocoaPods падает с Encoding::CompatibilityError на не-UTF8 локали.
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

echo "→ pod install"
pod install

SPM_RESOLVED="demo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
if [ -f "$SPM_RESOLVED" ]; then
  echo "→ xcodebuild -resolvePackageDependencies"
  xcodebuild -resolvePackageDependencies -workspace demo.xcworkspace -scheme demo -quiet
fi

echo "✓ SDK в демо актуален"
