#pragma once

//
//  Lendable.hpp
//
//  Copyright 2026 Example Pty Ltd
//

#include "EObject.hpp"
#include <cstdint>

// @generated
namespace library {

/// @brief The Lendable class.
///
/// Part of the library package.
// @generated
class Lendable : public virtual EObject {
public:
    /// @brief Destroys the object.
    // @generated
    virtual ~Lendable() = default;

    /// @brief The loanDays attribute.
    /// @return The current value of the loanDays attribute.
    // @generated
    virtual std::int32_t getLoanDays() const = 0;

    /// @brief Changes the loanDays attribute.
    /// @param value The new value.
    // @generated
    virtual void setLoanDays(std::int32_t value) = 0;

    /// @brief The onLoan attribute.
    /// @return The current value of the onLoan attribute.
    // @generated
    virtual bool getOnLoan() const = 0;

    /// @brief Changes the onLoan attribute.
    /// @param value The new value.
    // @generated
    virtual void setOnLoan(bool value) = 0;

protected:
    /// @brief Creates the part of an object that this class describes.
    // @generated
    Lendable() = default;
};

}
