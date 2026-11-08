# Write the same Ecore metamodel as Emfatic
swift-ecore convert Library-xcore.ecore Library-copy.emf
cat Library-copy.emf

# Output:
# Conversion completed: Library-copy.emf
# @GenModel(basePackage="org.example")
# @namespace(uri="http://www.example.org/lending", prefix="lend")
# package lending;
#
# class Library {
#     !unique attr String[1] name;
#     !resolve val Item[*] items;
#     !resolve val Writer[*] writers;
# }
#
# abstract class Item {
#     !unique id attr String[1] identifier;
#     !unique attr String[1] title;
#     !unique attr int copies = 1;
#
#     @"http://www.eclipse.org/emf/2011/Xcore"(body="{
#         copies > 0
#     }")
#     !unique op boolean isLoanable();
# }
#
# class Book extends Item {
#     !unique attr Genre genre;
#     ref Writer[+]#books authors;
# }
#
# class Writer {
#     !unique attr String[1] name;
#     ref Book[*]#authors books;
# }
#
# enum Genre {
#     fiction = 0;
#     poetry = 1;
#     reference = 2;
# }
