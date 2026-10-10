#pragma once

//
//  Book.hpp
//
//  Copyright 2026 Example Pty Ltd
//

#include "EObject.hpp"
#include "library/BookCategory.hpp"
#include "library/ISBN.hpp"
#include "library/Lendable.hpp"
#include "library/LibraryPackage.hpp"
#include "library/Named.hpp"
#include <cstdint>
#include <memory>
#include <string>

// @generated
namespace library { class Library; }

// @generated
namespace library { class Writer; }

// @generated
namespace library {

/// @brief The Book class.
///
/// Part of the library package.
// @generated
class Book final : public virtual Named, public virtual Lendable {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Book class.
    // @generated
    const ClassInfo &eClass() const override { return LibraryPackage::instance().bookClass(); }

    /// @brief The name attribute.
    /// @return The current value of the name attribute.
    // @generated
    const std::string &getName() const override { return m_name; }

    /// @brief Changes the name attribute.
    /// @param value The new value.
    // @generated
    void setName(const std::string &value) override { m_name = value; }

    /// @brief The loanDays attribute.
    /// @return The current value of the loanDays attribute.
    // @generated
    std::int32_t getLoanDays() const override { return m_loanDays; }

    /// @brief Changes the loanDays attribute.
    /// @param value The new value.
    // @generated
    void setLoanDays(std::int32_t value) override { m_loanDays = value; }

    /// @brief The onLoan attribute.
    /// @return The current value of the onLoan attribute.
    // @generated
    bool getOnLoan() const override { return m_onLoan; }

    /// @brief Changes the onLoan attribute.
    /// @param value The new value.
    // @generated
    void setOnLoan(bool value) override { m_onLoan = value; }

    /// @brief The pages attribute.
    /// @return The current value of the pages attribute.
    // @generated
    std::int32_t getPages() const { return m_pages; }

    /// @brief Changes the pages attribute.
    /// @param value The new value.
    // @generated
    void setPages(std::int32_t value) { m_pages = value; }

    /// @brief The category attribute.
    /// @return The current value of the category attribute.
    // @generated
    BookCategory getCategory() const { return m_category; }

    /// @brief Changes the category attribute.
    /// @param value The new value.
    // @generated
    void setCategory(BookCategory value) { m_category = value; }

    /// @brief The isbn attribute.
    /// @return The current value of the isbn attribute.
    // @generated
    const ISBN &getIsbn() const { return m_isbn; }

    /// @brief Changes the isbn attribute.
    /// @param value The new value.
    // @generated
    void setIsbn(const ISBN &value) { m_isbn = value; }

    /// @brief The author reference.
    /// @return The current value of the author reference.
    // @generated
    std::shared_ptr<Writer> getAuthor() const { return m_author.lock(); }

    /// @brief Changes the author reference.
    /// @param value The new value.
    // @generated
    void setAuthor(const std::shared_ptr<Writer> &value) { m_author = value; }

    /// @brief The library reference.
    /// @return The current value of the library reference.
    // @generated
    std::shared_ptr<Library> getLibrary() const { return m_library.lock(); }

    /// @brief Changes the library reference.
    /// @param value The new value.
    // @generated
    void setLibrary(const std::shared_ptr<Library> &value) { m_library = value; }

private:
    /// @brief The storage of the name attribute.
    // @generated
    std::string m_name;

    /// @brief The storage of the loanDays attribute.
    // @generated
    std::int32_t m_loanDays = 14;

    /// @brief The storage of the onLoan attribute.
    // @generated
    bool m_onLoan = false;

    /// @brief The storage of the pages attribute.
    // @generated
    std::int32_t m_pages = 100;

    /// @brief The storage of the category attribute.
    // @generated
    BookCategory m_category = BookCategory::Mystery;

    /// @brief The storage of the isbn attribute.
    // @generated
    ISBN m_isbn;

    /// @brief The storage of the author reference.
    // @generated
    std::weak_ptr<Writer> m_author;

    /// @brief The storage of the library reference.
    // @generated
    std::weak_ptr<Library> m_library;
};

}
