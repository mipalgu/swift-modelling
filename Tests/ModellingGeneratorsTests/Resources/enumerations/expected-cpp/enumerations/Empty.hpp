#pragma once

//
//  Empty.hpp
//

#include <cstdint>
#include <optional>
#include <string_view>

// @generated
namespace enumerations {

/// @brief The Empty enumeration.
// @generated
enum class Empty : std::int32_t {
};

/// @brief The text of the literal of a value of the Empty enumeration.
/// @param value The value to describe.
/// @return The literal as a model writes it, or an empty text for a value that has no literal.
// @generated
constexpr std::string_view literalOf(Empty value) {
    switch (value) {
    }
    return std::string_view();
}

/// @brief The value of the Empty enumeration that a literal stands for.
/// @param text The text of the literal as a model writes it.
/// @return The value, or no value if the text names no literal.
// @generated
inline std::optional<Empty> parseEmpty([[maybe_unused]] std::string_view text) {
    return std::nullopt;
}

}
