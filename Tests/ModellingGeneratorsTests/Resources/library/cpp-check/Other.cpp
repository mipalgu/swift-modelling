// A second translation unit that includes every header of the generated library model. Linking it with
// Check.cpp shows that the header-only code defines no symbol twice.

#include "EObject.hpp"
#include "library/Book.hpp"
#include "library/BookCategory.hpp"
#include "library/ISBN.hpp"
#include "library/Lendable.hpp"
#include "library/Library.hpp"
#include "library/LibraryFactory.hpp"
#include "library/LibraryPackage.hpp"
#include "library/Named.hpp"
#include "library/Writer.hpp"

/// The address of the package description as this translation unit sees it.
///
/// @return The address of the shared description.
const void *otherUnitPackage() {
    auto book = library::LibraryFactory::instance().createBook();
    book->setCategory(library::parseBookCategory("Biography").value_or(library::BookCategory::Mystery));
    return &library::LibraryPackage::instance();
}
