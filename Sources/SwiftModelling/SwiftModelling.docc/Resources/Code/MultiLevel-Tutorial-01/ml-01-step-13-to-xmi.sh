# Write the model as XMI instances of the linguistic metamodel
swift-ecore convert products.mdepth products.xmi
head -n 4 products.xmi

# Output:
# Conversion completed: products.xmi
# <?xml version="1.0" encoding="UTF-8"?>
# <ml:DeepModel ... xmlns:ml="urn:swift-ecore:multilevel:1.0" name="Catalogue" potencyVariant="metadepth" ...>
#     <levels name="Catalogue" potency="2" extensible="true">
#         <clabjects name="ProductType" identifier="<uuid>" kind="Node" leap="false" isAbstract="false">
