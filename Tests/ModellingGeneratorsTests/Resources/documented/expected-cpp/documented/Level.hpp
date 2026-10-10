#pragma once

//
//  Level.hpp
//

#include <cstdint>
#include <optional>
#include <string_view>

// @generated
namespace documented {

/// @brief The levels of an alarm.
/// Higher levels need quicker action.
// @generated
enum class Level : std::int32_t {
    /// @brief The Low literal.
    // @generated
    Low = 0,
    /// @brief Immediate action.
    /// Wake somebody.
    // @generated
    High = 1,
    /// @deprecated use High
    // @generated
    Old = 2,
};

/// @brief The text of the literal of a value of the Level enumeration.
/// @param value The value to describe.
/// @return The literal as a model writes it, or an empty text for a value that has no literal.
// @generated
constexpr std::string_view literalOf(Level value) {
    switch (value) {
    case Level::Low: return "Low";
    case Level::High: return "High";
    case Level::Old: return "Old";
    }
    return std::string_view();
}

/// @brief The value of the Level enumeration that a literal stands for.
/// @param text The text of the literal as a model writes it.
/// @return The value, or no value if the text names no literal.
// @generated
inline std::optional<Level> parseLevel(std::string_view text) {
    if (text == "Low") return Level::Low;
    if (text == "High") return Level::High;
    if (text == "Old") return Level::Old;
    return std::nullopt;
}

}
