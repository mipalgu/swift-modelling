#pragma once

//
//  Colour.hpp
//

#include <cstdint>
#include <optional>
#include <string_view>

// @generated
namespace datatypes {

/// @brief The Colour enumeration.
// @generated
enum class Colour : std::int32_t {
    /// @brief The Red literal.
    // @generated
    Red = 0,
};

/// @brief The text of the literal of a value of the Colour enumeration.
/// @param value The value to describe.
/// @return The literal as a model writes it, or an empty text for a value that has no literal.
// @generated
constexpr std::string_view literalOf(Colour value) {
    switch (value) {
    case Colour::Red: return "Red";
    }
    return std::string_view();
}

/// @brief The value of the Colour enumeration that a literal stands for.
/// @param text The text of the literal as a model writes it.
/// @return The value, or no value if the text names no literal.
// @generated
inline std::optional<Colour> parseColour(std::string_view text) {
    if (text == "Red") return Colour::Red;
    return std::nullopt;
}

}
