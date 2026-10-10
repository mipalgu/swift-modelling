#pragma once

//
//  Library.hpp
//
//  Copyright 2026 Example Pty Ltd
//

#include "EObject.hpp"
#include "library/LibraryPackage.hpp"
#include "library/Named.hpp"
#include <memory>
#include <string>
#include <vector>

// @generated
namespace library { class Book; }

// @generated
namespace library { class Writer; }

// @generated
namespace library {

/// @brief The Library class.
///
/// Part of the library package.
// @generated
class Library final : public virtual Named {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Library class.
    // @generated
    const ClassInfo &eClass() const override { return LibraryPackage::instance().libraryClass(); }

    /// @brief The name attribute.
    /// @return The current value of the name attribute.
    // @generated
    const std::string &getName() const override { return m_name; }

    /// @brief Changes the name attribute.
    /// @param value The new value.
    // @generated
    void setName(const std::string &value) override { m_name = value; }

    /// @brief The books reference.
    /// @return The values of the books reference, which the caller can change.
    // @generated
    std::vector<std::shared_ptr<Book>> &getBooks() { return m_books; }

    /// @brief The books reference.
    /// @return The values of the books reference.
    // @generated
    const std::vector<std::shared_ptr<Book>> &getBooks() const { return m_books; }

    /// @brief The writers reference.
    /// @return The values of the writers reference, which the caller can change.
    // @generated
    std::vector<std::shared_ptr<Writer>> &getWriters() { return m_writers; }

    /// @brief The writers reference.
    /// @return The values of the writers reference.
    // @generated
    const std::vector<std::shared_ptr<Writer>> &getWriters() const { return m_writers; }

private:
    /// @brief The storage of the name attribute.
    // @generated
    std::string m_name;

    /// @brief The storage of the books reference.
    // @generated
    std::vector<std::shared_ptr<Book>> m_books;

    /// @brief The storage of the writers reference.
    // @generated
    std::vector<std::shared_ptr<Writer>> m_writers;
};

}
