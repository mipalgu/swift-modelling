#!/bin/sh
# Downloads the EMF runtime libraries that generated Java code compiles against.
#
# Usage: Scripts/fetch-emf-runtime.sh [directory]
#
# The jars for org.eclipse.emf.common and org.eclipse.emf.ecore are fetched from Maven Central into
# the directory (default: emf-runtime below the temporary directory) unless they are already there.
# The class path that names them is printed on standard output, so that it can be used directly:
#
#   export EMF_RUNTIME_CLASSPATH="$(Scripts/fetch-emf-runtime.sh)"
#
# Progress messages go to standard error. Set EMF_COMMON_VERSION or EMF_ECORE_VERSION to choose a
# version; by default the latest release that Maven Central lists is used.

set -eu

repository="https://repo1.maven.org/maven2/org/eclipse/emf"
temporary="${TMPDIR:-/tmp}"
directory="${1:-${temporary%/}/emf-runtime}"
directory="${directory%/}"

# Prints the latest release of an artifact, as listed in its Maven metadata.
latest_release() {
    curl -fsSL "${repository}/$1/maven-metadata.xml" \
        | sed -n 's:.*<release>\(.*\)</release>.*:\1:p' | head -n 1
}

# Downloads one jar unless it exists, and prints its path.
fetch() {
    artifact="$1"
    version="$2"
    jar="${directory}/${artifact}-${version}.jar"
    if [ ! -s "${jar}" ]; then
        echo "Fetching ${artifact} ${version}" >&2
        curl -fsSL -o "${jar}.part" "${repository}/${artifact}/${version}/${artifact}-${version}.jar"
        mv "${jar}.part" "${jar}"
    fi
    printf '%s' "${jar}"
}

mkdir -p "${directory}"
common_version="${EMF_COMMON_VERSION:-$(latest_release org.eclipse.emf.common)}"
ecore_version="${EMF_ECORE_VERSION:-$(latest_release org.eclipse.emf.ecore)}"

if [ -z "${common_version}" ] || [ -z "${ecore_version}" ]; then
    echo "Cannot determine the EMF versions; set EMF_COMMON_VERSION and EMF_ECORE_VERSION" >&2
    exit 1
fi

common_jar="$(fetch org.eclipse.emf.common "${common_version}")"
ecore_jar="$(fetch org.eclipse.emf.ecore "${ecore_version}")"
printf '%s:%s\n' "${common_jar}" "${ecore_jar}"
