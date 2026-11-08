# Pass a number after the drawing, and add up the areas
swift-xtend run Measure.xtend --model poster.xmi -m Shapes.ecore -n largerThan --argument 1900
swift-xtend run Measure.xtend --model poster.xmi -m Shapes.ecore -n total

# Output:
# [frame, sun]
# 27762
