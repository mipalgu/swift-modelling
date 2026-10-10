#pragma once

//
//  Status.hpp
//

#include <cstdint>
#include <optional>
#include <string_view>

// @generated
namespace company::projects {

/// @brief The Status enumeration.
// @generated
enum class Status : std::int32_t {
    /// @brief The Proposed literal.
    // @generated
    Proposed = 0,
    /// @brief The Active literal.
    // @generated
    Active = 1,
    /// @brief The Finished literal.
    // @generated
    Finished = 2,
};

/// @brief The text of the literal of a value of the Status enumeration.
/// @param value The value to describe.
/// @return The literal as a model writes it, or an empty text for a value that has no literal.
// @generated
constexpr std::string_view literalOf(Status value) {
    switch (value) {
    case Status::Proposed: return "Proposed";
    case Status::Active: return "Active";
    case Status::Finished: return "Finished";
    }
    return std::string_view();
}

/// @brief The value of the Status enumeration that a literal stands for.
/// @param text The text of the literal as a model writes it.
/// @return The value, or no value if the text names no literal.
// @generated
inline std::optional<Status> parseStatus(std::string_view text) {
    if (text == "Proposed") return Status::Proposed;
    if (text == "Active") return Status::Active;
    if (text == "Finished") return Status::Finished;
    return std::nullopt;
}

}
