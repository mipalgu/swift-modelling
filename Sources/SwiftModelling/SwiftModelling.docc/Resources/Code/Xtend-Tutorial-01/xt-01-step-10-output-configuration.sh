# Generate the picture into out and the legend into docs
swift-xtend generate Pictures.xtend --include Measure.xtend \
    --model poster.xmi -m Shapes.ecore --output out --output-configuration docs=docs
cat docs/poster.md

# Output:
# out/poster.svg
# docs:docs/poster.md
# # Poster
#
# Shapes: frame, sun, door
#
# - frame is a 200 by 120 rectangle, area 24000 (large)
# - sun is a circle of radius 25, area 1962 (small)
# - door is a 30 by 60 rectangle, area 1800 (small)
# Total area: 27762
