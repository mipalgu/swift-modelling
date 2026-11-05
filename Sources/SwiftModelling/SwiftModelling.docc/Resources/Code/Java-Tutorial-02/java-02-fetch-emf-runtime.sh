#!/bin/sh
# Downloads the EMF runtime libraries that generated Java code compiles against.
#
# Usage: Scripts/fetch-emf-runtime.sh [directory]
#
# The jars for org.eclipse.emf.common, org.eclipse.emf.ecore, org.eclipse.emf.ecore.xmi the OSGi framework and the Eclipse core runtime are fetched from Maven Central into
# the directory (default: emf-runtime below the temporary directory) unless they are already there.
# The class path that names them is printed on standard output, so that it can be used directly:
#
#   export EMF_RUNTIME_CLASSPATH="$(Scripts/fetch-emf-runtime.sh)"
#
# Progress messages go to standard error. Set EMF_COMMON_VERSION or EMF_ECORE_VERSION to choose a
# version; by default the latest release that Maven Central lists is used.

set -eu

central="https://repo1.maven.org/maven2"
repository="${central}/org/eclipse/emf"
osgi_repository="${central}/org/osgi"
platform_repository="${central}/org/eclipse/platform"
temporary="${TMPDIR:-/tmp}"
directory="${1:-${temporary%/}/emf-runtime}"
directory="${directory%/}"

# Prints the latest release of an artifact, as listed in its Maven metadata.
latest_release() {
    curl -fsSL "${base:-${repository}}/$1/maven-metadata.xml" \
        | sed -n 's:.*<release>\(.*\)</release>.*:\1:p' | head -n 1
}

# Downloads one jar unless it exists, and prints its path.
fetch() {
    base="${base:-${repository}}"
    artifact="$1"
    version="$2"
    jar="${directory}/${artifact}-${version}.jar"
    if [ ! -s "${jar}" ]; then
        echo "Fetching ${artifact} ${version}" >&2
        curl -fsSL -o "${jar}.part" "${base}/${artifact}/${version}/${artifact}-${version}.jar"
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
xmi_version="${EMF_XMI_VERSION:-$(latest_release org.eclipse.emf.ecore.xmi)}"
xmi_jar="$(fetch org.eclipse.emf.ecore.xmi "${xmi_version}")"
base="${osgi_repository}"
osgi_version="${OSGI_FRAMEWORK_VERSION:-$(latest_release org.osgi.framework)}"
osgi_jar="$(fetch org.osgi.framework "${osgi_version}")"
base="${platform_repository}"
runtime_version="${ECLIPSE_RUNTIME_VERSION:-$(latest_release org.eclipse.core.runtime)}"
runtime_jar="$(fetch org.eclipse.core.runtime "${runtime_version}")"
printf '%s:%s:%s:%s:%s\n' "${common_jar}" "${ecore_jar}" "${xmi_jar}" "${osgi_jar}" "${runtime_jar}"
