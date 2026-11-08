# Write the Ecore metamodel that came from Xcore back as Xcore
swift-ecore convert Library-xcore.ecore Library-copy.xcore
cat Library-copy.xcore

# Output:
# Conversion completed: Library-copy.xcore
# @Ecore(nsURI="http://www.example.org/lending", nsPrefix="lend")
# package org.example.lending
#
# class Library {
#     String[1] name
#     contains Item[] items
#     contains Writer[] writers
# }
#
# abstract class Item {
#     id String[1] identifier
#     String[1] title
#     int copies = "1"
#     op boolean isLoanable() {
#         copies > 0
#     }
# }
#
# class Book extends Item {
#     Genre genre
#     refers Writer[+] authors opposite books
# }
#
# class Writer {
#     String[1] name
#     refers Book[] books opposite authors
# }
#
# enum Genre {
#     fiction
#     poetry = 1
#     reference = 2
# }
