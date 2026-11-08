# Run the generator and show the picture it wrote
swift-xtend generate Pictures.xtend --model poster.xmi -m Shapes.ecore --output out
cat out/poster.svg

# Output:
# out/poster.svg
# <svg xmlns="http://www.w3.org/2000/svg" width="200" height="120">
#   <rect id="frame" x="0" y="0" width="200" height="120" fill="navy"/>
#   <circle id="sun" cx="150" cy="40" r="25" fill="gold"/>
#   <rect id="door" x="40" y="60" width="30" height="60" fill="none" stroke="black"/>
# </svg>
