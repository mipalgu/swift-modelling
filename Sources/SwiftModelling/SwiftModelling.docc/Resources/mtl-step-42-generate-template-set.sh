# SwiftGenerator/ holds SwiftGenerator.mtl and templateset.json
swift-mtl generate --template-set SwiftGenerator/ --model Company.ecore --output generated/

# Replace single modules of the set with those of another directory
swift-mtl generate --template-set SwiftGenerator/ --template-path my-changes/ \
  --model Company.ecore --output generated/
