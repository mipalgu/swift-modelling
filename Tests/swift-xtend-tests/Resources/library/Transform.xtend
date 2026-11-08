import catalogue.Catalogue
import catalogue.Entry
import library.Book
import library.Library

class Transform {
    def create new Catalogue toCatalogue(Library library) {
        name = library.name + ' Catalogue'
        entries += library.books.map[entry]
    }

    def create new Entry entry(Book book) {
        title = book.title
    }
}
