import library.Book
import library.Library

class Labels {
    def dispatch label(Book book) {
        'book ' + book.title
    }

    def dispatch label(Library library) {
        'library ' + library.name
    }

    def dispatch weigh(Book book, int factor) {
        book.pages * factor
    }

    def dispatch weigh(Library library, int factor) {
        library.books.size * factor
    }
}
