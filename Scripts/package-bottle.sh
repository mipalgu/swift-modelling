#!/bin/sh
#
# Assembles the Homebrew keg for a release build of the command line tools.
#
# The executables and the resource bundles they load (bundled templates,
# transformations and metamodels) are placed together in `libexec`, because
# a Swift package finds its resource bundles next to the running executable.
# The `bin` directory holds small launcher scripts that resolve their own
# location (following the symbolic links Homebrew creates) and start the
# executable in `libexec`.
#
# Usage: Scripts/package-bottle.sh <build-directory> <keg-directory>
#
#   build-directory  the release products, e.g. `.build/release`
#   keg-directory    the keg to create, e.g. `swift-modelling/0.2.1`

set -eu

if [ "$#" -ne 2 ]; then
    echo "usage: $0 <build-directory> <keg-directory>" >&2
    exit 64
fi

build_directory=$1
keg_directory=$2
tools="swift-ecore swift-atl swift-mtl"

mkdir -p "$keg_directory/bin" "$keg_directory/libexec"

for tool in $tools; do
    cp "$build_directory/$tool" "$keg_directory/libexec/"
    launcher="$keg_directory/bin/$tool"
    cat > "$launcher" <<EOF
#!/bin/sh
script=\$0
while [ -L "\$script" ]; do
    target=\$(readlink "\$script")
    case \$target in
        /*) script=\$target ;;
        *) script=\$(dirname "\$script")/\$target ;;
    esac
done
exec "\$(cd "\$(dirname "\$script")/../libexec" && pwd)/$tool" "\$@"
EOF
    chmod 755 "$launcher"
done

# Resource bundles: `.bundle` directories on macOS, `.resources` on Linux.
# Bundles of test targets are not part of the installation.
found=0
for bundle in "$build_directory"/*.bundle "$build_directory"/*.resources; do
    [ -d "$bundle" ] || continue
    case $(basename "$bundle") in
        *Tests.bundle | *-tests.bundle | *Tests.resources | *-tests.resources) continue ;;
    esac
    cp -R "$bundle" "$keg_directory/libexec/"
    found=1
done
if [ "$found" -eq 0 ]; then
    echo "error: no resource bundles found in $build_directory" >&2
    exit 1
fi
