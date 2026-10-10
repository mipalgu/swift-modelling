#pragma once

//
//  LibraryFactory.hpp
//
//  Copyright 2026 Example Pty Ltd
//

#include "EObject.hpp"
#include "library/Book.hpp"
#include "library/Library.hpp"
#include "library/Writer.hpp"
#include <memory>
#include <string_view>

// @generated
namespace library {

/// @brief The factory of the library package.
///
/// The factory creates the objects of the classes of the package that have instances.
// @generated
class LibraryFactory final {
public:
    /// @brief The shared factory of the package.
    /// @return The only instance.
    // @generated
    static const LibraryFactory &instance() {
        static const LibraryFactory factory;
        return factory;
    }

    /// @brief Creates a new Book object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Book> createBook() const { return std::make_shared<Book>(); }

    /// @brief Creates a new Writer object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Writer> createWriter() const { return std::make_shared<Writer>(); }

    /// @brief Creates a new Library object.
    /// @return An object with all features at their defaults.
    // @generated
    std::shared_ptr<Library> createLibrary() const { return std::make_shared<Library>(); }

    /// @brief Creates an object for the name of a class of the package.
    /// @param className The name of the class in the model.
    /// @return A new object, or a null pointer if the package has no class with instances of that name.
    // @generated
    std::shared_ptr<EObject> create([[maybe_unused]] std::string_view className) const {
        if (className == "Book") return createBook();
        if (className == "Writer") return createWriter();
        if (className == "Library") return createLibrary();
        return nullptr;
    }
};

}
