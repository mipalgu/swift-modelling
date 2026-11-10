# Transform the deep view of the bottom level into a price list
swift-atl transform Shelf2PriceList.atl --source products.mdepth --deep-view 0 \
  --target price-list.xmi --quiet
cat price-list.xmi

# Output:
# <?xml version="1.0" encoding="UTF-8"?>
# <xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:pricelist="http://example.org/pricelist" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
#     <pricelist:Entry product="manual" kind="Book" price="35.0" gst="0.0"/>
#     <pricelist:Entry product="monthly" kind="Magazine" price="9.5" gst="10.0"/>
# </xmi:XMI>
