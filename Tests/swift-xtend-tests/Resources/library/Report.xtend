import library.Book
import library.Library
import org.eclipse.emf.ecore.resource.Resource

class Report {
    def describe(Library library) {
        library.name + ' has ' + library.books.size + ' books'
    }

    def titles(Library library) {
        library.books.map[title]
    }

    def count(Library library) {
        library.books.size
    }

    def firstBook(Library library) {
        library.books.head
    }

    def longBooks(Library library, int minimum) {
        library.books.filter[pages >= minimum].map[title].toList
    }

    def pageCount(Book book) {
        book.pages
    }

    def allBooks(java.util.List<Book> books) {
        books.size
    }

    def resourceRoots(Resource resource) {
        resource.contents.size
    }

    def retire(Library library) {
        library.books.forEach[available = false]
    }
}
