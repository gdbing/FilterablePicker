#!/bin/sh
set -eu

package_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$package_dir"
developer_dir=$(xcode-select -p)
testing_plugin="$developer_dir/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib"
testing_frameworks="$developer_dir/Library/Developer/Frameworks"
testing_libraries="$developer_dir/Library/Developer/usr/lib"

# Some Command Line Tools releases omit these installed Testing paths from
# their build and runtime search paths. Supply them for this invocation only.
if [ -f "$testing_plugin" ] && [ -d "$testing_frameworks/Testing.framework" ] && [ -f "$testing_libraries/lib_TestingInterop.dylib" ]; then
    exec swift test \
        -Xswiftc -load-plugin-library -Xswiftc "$testing_plugin" \
        -Xlinker -rpath -Xlinker "$testing_frameworks" \
        -Xlinker -rpath -Xlinker "$testing_libraries" "$@"
fi

exec swift test "$@"
