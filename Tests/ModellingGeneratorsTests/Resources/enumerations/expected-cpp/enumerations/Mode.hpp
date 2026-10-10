#pragma once

//
//  Mode.hpp
//

#include <cstdint>
#include <optional>
#include <string_view>

// @generated
namespace enumerations {

/// @brief The Mode enumeration.
// @generated
enum class Mode : std::int32_t {
    /// @brief The default literal.
    // @generated
    default_ = 0,
    /// @brief The fastForward literal.
    // @generated
    fastForward = 1,
    /// @brief The HTTPServer literal.
    // @generated
    HTTPServer = 2,
    /// @brief The _ literal.
    // @generated
    _ = 3,
    /// @brief The quote literal.
    // @generated
    quote = 4,
};

/// @brief The text of the literal of a value of the Mode enumeration.
/// @param value The value to describe.
/// @return The literal as a model writes it, or an empty text for a value that has no literal.
// @generated
constexpr std::string_view literalOf(Mode value) {
    switch (value) {
    case Mode::default_: return "default";
    case Mode::fastForward: return "fastForward";
    case Mode::HTTPServer: return "HTTPServer";
    case Mode::_: return "_";
    case Mode::quote: return "say \"hi\"";
    }
    return std::string_view();
}

/// @brief The value of the Mode enumeration that a literal stands for.
/// @param text The text of the literal as a model writes it.
/// @return The value, or no value if the text names no literal.
// @generated
inline std::optional<Mode> parseMode(std::string_view text) {
    if (text == "default") return Mode::default_;
    if (text == "fastForward") return Mode::fastForward;
    if (text == "HTTPServer") return Mode::HTTPServer;
    if (text == "_") return Mode::_;
    if (text == "say \"hi\"") return Mode::quote;
    return std::nullopt;
}

}
