# Put the generator and its descriptor into the directory of the set, and
# create my-changes/ for your own versions of modules of the set
mkdir -p SwiftGenerator my-changes
cp SwiftGenerator.mtl templateset.json SwiftGenerator/

swift-mtl generate --template-set SwiftGenerator/ --model Company.ecore --output generated/

# Replace single modules of the set with those of another directory
swift-mtl generate --template-set SwiftGenerator/ --template-path my-changes/ \
  --model Company.ecore --output generated/
