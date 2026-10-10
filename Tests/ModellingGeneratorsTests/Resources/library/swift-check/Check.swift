import ECore
import EMFBase
import Foundation
import Model

/// Reports a failed check and stops with a failure status.
func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        print("FAILED: \(message)")
        exit(1)
    }
}

/// Exercises the generated library model: references that keep their opposites in step, weak references,
/// default values, the reflective methods and the factory.
@main
struct Check {
    static func main() {
        let factory = LibraryPackage.shared.factory
        let library = factory.createLibrary()
        let writer = factory.createWriter()
        let book = factory.createBook()

        book.name = "Dune"
        library.books.append(book)
        book.library = library
        book.author = writer
        expect(writer.books.count == 1 && writer.books[0] === book, "setting the author adds the book to the writer")
        expect(book.library === library, "the library of the book is kept")

        let other = factory.createWriter()
        book.author = other
        expect(writer.books.isEmpty && other.books.count == 1, "changing the author moves the book")
        book.author = nil
        expect(other.books.isEmpty, "clearing the author removes the book")

        expect(book.pages == 100 && book.loanDays == 14 && !book.onLoan, "defaults of the model")
        expect(book.category == .Mystery && book.isbn == nil, "the first literal and no value are the defaults")

        let features = LibraryPackage.shared.eBook.allStructuralFeatures
        let pages = features.first { $0.name == "pages" }!
        book.eSet(pages, 250)
        expect(book.pages == 250 && book.eIsSet(pages), "eSet changes the value")
        expect((book.eGet(pages) as? Int) == 250, "eGet reads the value")
        book.eUnset(pages)
        expect(book.pages == 100 && !book.eIsSet(pages), "eUnset restores the default")

        let aliases = LibraryPackage.shared.eWriter.allStructuralFeatures.first { $0.name == "aliases" }!
        writer.eSet(aliases, EcoreValueArray(["a", "b"]))
        expect(writer.aliases == ["a", "b"], "many-valued values are stored")
        expect((writer.eGet(aliases) as? EcoreValueArray)?.values.count == 2, "many-valued values are read")
        expect(writer.eIsSet(aliases), "a many-valued feature with values is set")

        expect(factory.create(LibraryPackage.shared.eBook) is Book, "the factory creates objects for metaclasses")
        expect(factory.create(LibraryPackage.shared.eNamed) == nil, "no object for an abstract class")
        expect(book == book && book != factory.createBook(), "equality is by identifier")
        expect(Set([book, book]).count == 1, "hashing is by identifier")

        var temporary: Writer? = factory.createWriter()
        book.author = temporary
        temporary = nil
        expect(book.author == nil, "a weak reference does not keep its target alive")

        expect(BookCategory(literalText: "Biography") == .Biography, "literal text is converted")
        expect(BookCategory.Mystery.literalText == "Mystery", "literals are written")
        let categories = BookCategory.allCases
        expect(categories.count == 3 && categories.contains(.Biography), "every literal is iterable")
        for category in categories {
            let encoded = try! JSONEncoder().encode(category)
            let decoded = try! JSONDecoder().decode(BookCategory.self, from: encoded)
            expect(decoded == category, "a literal survives a JSON round trip")
        }
        expect(LibraryPackage.shared.ePackage.eClassifiers.count == 7, "the package holds every classifier")
        expect(book.eClass.name == "Book" && book.eClass.eSuperTypes.count == 2, "metaclasses know their supertypes")

        print("checks passed")
    }
}
