# Read the XMI document back and write it in the MetaDepth notation again
swift-ecore convert products.xmi products-copy.mdepth
cat products-copy.mdepth

# Output:
# Conversion completed: products-copy.mdepth
# Model Catalogue@2 {
#   Node ProductType {
#     gst@1 : double = 10.0;
#     price : double = 0.0;
#     positivePrice@2 : $self.price > 0$
#   }
# }
# Catalogue Bookshop {
#   ProductType Book {
#     pages : int;
#     gst = 0.0;
#   }
#   ProductType Magazine {
#     issue : int;
#   }
# }
# Bookshop Shelf {
#   Book manual {
#     price = 35.0;
#     pages = 120;
#   }
#   Magazine monthly {
#     price = 9.5;
#     issue = 42;
#   }
# }
