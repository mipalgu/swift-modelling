import org.eclipse.xtext.generator.IFileSystemAccess

class Maths {
    def add(int a, int b) {
        a + b
    }

    def scale(double factor, boolean doubled) {
        if (doubled) factor * 2 else factor
    }

    def greet(String name) {
        'Hello, ' + name + '!'
    }

    def say(String text) {
        println(text)
    }

    def void nothing() {
    }

    def broken() {
        1 / 0
    }

    def needsFile(IFileSystemAccess fsa) {
        1
    }
}
