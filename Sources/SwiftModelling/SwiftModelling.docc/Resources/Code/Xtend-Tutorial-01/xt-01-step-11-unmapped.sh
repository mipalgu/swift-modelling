# Generate without mapping the docs output configuration
# Expected error: the generator writes to docs, which no option maps to a directory
swift-xtend generate Pictures.xtend --include Measure.xtend \
    --model poster.xmi -m Shapes.ecore --output out

# Output:
# Error: Pictures.xtend:14:13: error: Unknown output configuration 'docs' [xtend.runtime.fileAccess]
