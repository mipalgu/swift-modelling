#pragma once

//
//  Writer.hpp
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
namespace library {

/// @brief The Writer class.
///
/// Part of the library package.
// @generated
class Writer final : public virtual Named {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Writer class.
    // @generated
    const ClassInfo &eClass() const override { return LibraryPackage::instance().writerClass(); }

    /// @brief The name attribute.
    /// @return The current value of the name attribute.
    // @generated
    const std::string &getName() const override { return m_name; }

    /// @brief Changes the name attribute.
    /// @param value The new value.
    // @generated
    void setName(const std::string &value) override { m_name = value; }

    /// @brief The aliases attribute.
    /// @return The values of the aliases attribute, which the caller can change.
    // @generated
    std::vector<std::string> &getAliases() { return m_aliases; }

    /// @brief The aliases attribute.
    /// @return The values of the aliases attribute.
    // @generated
    const std::vector<std::string> &getAliases() const { return m_aliases; }

    /// @brief The books reference.
    /// @return The values of the books reference, which the caller can change.
    // @generated
    std::vector<std::weak_ptr<Book>> &getBooks() { return m_books; }

    /// @brief The books reference.
    /// @return The values of the books reference.
    // @generated
    const std::vector<std::weak_ptr<Book>> &getBooks() const { return m_books; }

private:
    /// @brief The storage of the name attribute.
    // @generated
    std::string m_name;

    /// @brief The storage of the aliases attribute.
    // @generated
    std::vector<std::string> m_aliases;

    /// @brief The storage of the books reference.
    // @generated
    std::vector<std::weak_ptr<Book>> m_books;
};

}
