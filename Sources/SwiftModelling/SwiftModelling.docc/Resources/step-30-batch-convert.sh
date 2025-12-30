for file in *.xmi; do
  swift-ecore convert "$file" "${file%.xmi}.json"
done
