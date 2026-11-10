# Generate the price list from the deep view of the bottom level
swift-mtl generate price-list.mtl --model products.mdepth --deep-view 0 --output generated
cat generated/price-list.txt

# Output:
# ✓ Generation complete
# Price list
# - manual (Book): 35.0 plus 0.0 per cent GST
# - monthly (Magazine): 9.5 plus 10.0 per cent GST
