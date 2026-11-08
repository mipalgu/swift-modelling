# Double the size of the drawing and write the changed model to a new file
swift-xtend run Measure.xtend --model poster.xmi -m Shapes.ecore -n enlarge --argument 2 \
    --output poster-large.xmi
swift-xtend run Measure.xtend --model poster-large.xmi -m Shapes.ecore -n describe

# Output:
# frame is a 400 by 240 rectangle; sun is a circle of radius 50; door is a 60 by 120 rectangle
