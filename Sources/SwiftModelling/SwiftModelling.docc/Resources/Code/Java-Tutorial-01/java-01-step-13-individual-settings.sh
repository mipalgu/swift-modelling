swift-ecore genmodel extlibrary.ecore \
    --base-package org.eclipse.emf.examples \
    --prefix EXTLibrary \
    --defaults headless \
    --root-extends-class 'org.eclipse.emf.ecore.impl.MinimalEObjectImpl$Container' \
    --operation-reflection \
    --import-organizing \
    --output custom/extlibrary.genmodel
