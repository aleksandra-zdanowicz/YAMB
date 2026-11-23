#!/bin/zsh
# Builds YambCore and runs the rule checks.
# Uses SwiftPM when it works (i.e. with Xcode installed), otherwise plain swiftc.
set -e
cd "${0:A:h}"

if swift build --product YambChecks >/dev/null 2>&1; then
  exec swift run --skip-build YambChecks
fi

# Fallback for a Command Line Tools install whose newest SDK is ahead of its compiler:
# pick the newest SDK that actually compiles.
OUT=.build/manual
mkdir -p $OUT
echo 'print("")' > $OUT/probe.swift
SDK=""
for candidate in $(ls -d /Library/Developer/CommandLineTools/SDKs/MacOSX*.*.sdk(N) | sort -rV); do
  if swiftc -sdk "$candidate" $OUT/probe.swift -o $OUT/probe >/dev/null 2>&1; then SDK=$candidate; break; fi
done
[[ -z $SDK ]] && { echo "No working Swift SDK found. Install Xcode."; exit 1; }

swiftc -sdk "$SDK" -parse-as-library -emit-library -static -emit-module \
  -module-name YambCore -emit-module-path $OUT/YambCore.swiftmodule \
  -o $OUT/libYambCore.a Sources/YambCore/*.swift
swiftc -sdk "$SDK" -I $OUT -L $OUT -lYambCore Sources/YambChecks/main.swift -o $OUT/YambChecks
exec $OUT/YambChecks
