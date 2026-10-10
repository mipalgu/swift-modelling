#pragma once

//
//  Mode.hpp
//

#include <cstdint>
#include <optional>
#include <string_view>

// @generated
namespace cnames {

/// @brief The Mode enumeration.
// @generated
enum class Mode : std::int32_t {
    /// @brief The and literal.
    // @generated
    and_ = 0,
    /// @brief The default literal.
    // @generated
    default_ = 1,
    /// @brief The int literal.
    // @generated
    int_ = 2,
    /// @brief The NULL literal.
    // @generated
    NULL_ = 3,
    /// @brief The new literal.
    // @generated
    new_ = 4,
    /// @brief The true literal.
    // @generated
    true_ = 5,
};

/// @brief The text of the literal of a value of the Mode enumeration.
/// @param value The value to describe.
/// @return The literal as a model writes it, or an empty text for a value that has no literal.
// @generated
constexpr std::string_view literalOf(Mode value) {
    switch (value) {
    case Mode::and_: return "and";
    case Mode::default_: return "default";
    case Mode::int_: return "int";
    case Mode::NULL_: return "NULL";
    case Mode::new_: return "new";
    case Mode::true_: return "true";
    }
    return std::string_view();
}

/// @brief The value of the Mode enumeration that a literal stands for.
/// @param text The text of the literal as a model writes it.
/// @return The value, or no value if the text names no literal.
// @generated
inline std::optional<Mode> parseMode(std::string_view text) {
    if (text == "and") return Mode::and_;
    if (text == "default") return Mode::default_;
    if (text == "int") return Mode::int_;
    if (text == "NULL") return Mode::NULL_;
    if (text == "new") return Mode::new_;
    if (text == "true") return Mode::true_;
    return std::nullopt;
}

}
