# Validate a copy of the model with two mistakes at the bottom level
# Expected error: gst cannot be set at level 0, and the price is not positive
swift-ecore validate products-errors.mdepth

# Output:
# error: no feature 'gst' is visible at 'Shelf.monthly'
# error: constraint 'positivePrice' of 'Catalogue.ProductType' is violated on 'Shelf.monthly'
# Error: Validation failed: 2 error(s), 0 warning(s)
