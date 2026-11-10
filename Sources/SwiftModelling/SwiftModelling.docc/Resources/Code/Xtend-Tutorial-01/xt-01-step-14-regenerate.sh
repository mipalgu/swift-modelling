# Generate from the enlarged drawing
swift-xtend generate Pictures.xtend --include Measure.xtend \
    --model poster-large.xmi -m Shapes.ecore --output out --output-configuration docs=docs
cat out/poster-large.svg

# Output:
# out/poster-large.svg
# docs:docs/poster-large.md
# <svg xmlns="http://www.w3.org/2000/svg" width="400" height="240">
#   <rect id="frame" x="0" y="0" width="400" height="240" fill="navy"/>
#   <circle id="sun" cx="300" cy="80" r="50" fill="gold"/>
#   <rect id="door" x="80" y="120" width="60" height="120" fill="none" stroke="black"/>
# </svg>
