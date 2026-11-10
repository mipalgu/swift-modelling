import library.Book
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess

class Catalogue {
    def doGenerate(Resource resource, IFileSystemAccess fsa) {
        for (book : resource.allContents.toIterable.filter(Book)) {
            fsa.generateFile(book.title + '.txt', book.compile)
        }
        fsa.generateFile('index.txt', 'docs', 'Index of books')
        println('Generated the catalogue')
    }

    def compile(Book book) '''
        Title: «book.title»
        Pages: «book.pages»
    '''
}
