# Pass named shapes to the dispatch method area, and then the first shape
swift-xtend run Measure.xtend --model poster.xmi -m Shapes.ecore -n area --object sun
swift-xtend run Measure.xtend --model poster.xmi -m Shapes.ecore -n area --object door
swift-xtend run Measure.xtend --model poster.xmi -m Shapes.ecore -n area

# Output:
# 1962
# 1800
# 24000
