#pragma once

//
//  BookCategory.hpp
//
//  Copyright 2026 Example Pty Ltd
//

#include <cstdint>
#include <optional>
#include <string_view>

// @generated
namespace library {

/// @brief The BookCategory enumeration.
// @generated
enum class BookCategory : std::int32_t {
    /// @brief The Mystery literal.
    // @generated
    Mystery = 0,
    /// @brief The ScienceFiction literal.
    // @generated
    ScienceFiction = 1,
    /// @brief The Biography literal.
    // @generated
    Biography = 2,
};

/// @brief The text of the literal of a value of the BookCategory enumeration.
/// @param value The value to describe.
/// @return The literal as a model writes it, or an empty text for a value that has no literal.
// @generated
constexpr std::string_view literalOf(BookCategory value) {
    switch (value) {
    case BookCategory::Mystery: return "Mystery";
    case BookCategory::ScienceFiction: return "ScienceFiction";
    case BookCategory::Biography: return "Biography";
    }
    return std::string_view();
}

/// @brief The value of the BookCategory enumeration that a literal stands for.
/// @param text The text of the literal as a model writes it.
/// @return The value, or no value if the text names no literal.
// @generated
inline std::optional<BookCategory> parseBookCategory(std::string_view text) {
    if (text == "Mystery") return BookCategory::Mystery;
    if (text == "ScienceFiction") return BookCategory::ScienceFiction;
    if (text == "Biography") return BookCategory::Biography;
    return std::nullopt;
}

}
