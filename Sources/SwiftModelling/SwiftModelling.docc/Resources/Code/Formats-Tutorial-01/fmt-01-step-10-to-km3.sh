# Write an Ecore metamodel as KM3; what KM3 cannot express is reported
swift-ecore convert Library.ecore Library.km3
cat Library.km3

# Output:
# warning: KM3 cannot express the annotation http://www.eclipse.org/emf/2002/GenModel of 'library'; it is dropped
# warning: KM3 cannot express the identifier flag of 'library::Book.isbn'; it is dropped
# warning: KM3 cannot express the default value '100' of 'library::Book.pages'; it is dropped
# warning: KM3 cannot express the value 0 (it becomes 1) of 'library::BookCategory.Fiction'; it is dropped
# warning: KM3 cannot express the value 1 (it becomes 2) of 'library::BookCategory.Biography'; it is dropped
# warning: KM3 cannot express the value 2 (it becomes 3) of 'library::BookCategory.Reference'; it is dropped
# ...
# -- @nsURI http://www.example.org/library
# -- @nsPrefix lib
# package library {
#
#     class Library {
#         attribute name ordered unique : String;
#         reference books[*] ordered container : Book;
#         reference writers[*] ordered container : Writer;
#     }
#
#     class Book {
#         attribute isbn ordered unique : String;
#         attribute title ordered unique : String;
#         attribute pages[0-1] ordered unique : Integer;
#         attribute category[0-1] ordered unique : BookCategory;
#         reference authors[*] ordered : Writer oppositeOf books;
#     }
#
#     class Writer {
#         attribute name ordered unique : String;
#         reference books[*] ordered : Book oppositeOf authors;
#     }
#
#     enumeration BookCategory {
#         literal Fiction;
#         literal Biography;
#         literal Reference;
#     }
# }
#
# package PrimitiveTypes {
#     datatype Integer;
#     datatype String;
# }
