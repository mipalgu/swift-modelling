#pragma once

//
//  Shape.hpp
//

#include "EObject.hpp"
#include "classes/Colour.hpp"
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

// @generated
namespace classes { class Canvas; }

// @generated
namespace classes {

/// @brief A shape on a canvas.
/// Shapes know their bounds.
/// @since 1.2
// @generated
class Shape : public virtual EObject {
public:
    /// @brief Destroys the object.
    // @generated
    virtual ~Shape() = default;

    /// @brief The label of the shape.
    /// @return The current value of the label attribute.
    // @generated
    virtual const std::string &getLabel() const = 0;

    /// @brief Changes the label attribute.
    /// @param value The new value.
    // @generated
    virtual void setLabel(const std::string &value) = 0;

    /// @brief The visible attribute.
    /// @return The current value of the visible attribute.
    // @generated
    virtual bool getVisible() const = 0;

    /// @brief Changes the visible attribute.
    /// @param value The new value.
    // @generated
    virtual void setVisible(bool value) = 0;

    /// @brief The weight attribute.
    /// @return The current value of the weight attribute.
    // @generated
    virtual double getWeight() const = 0;

    /// @brief Changes the weight attribute.
    /// @param value The new value.
    // @generated
    virtual void setWeight(double value) = 0;

    /// @brief The tags attribute.
    /// @return The values of the tags attribute, which the caller can change.
    // @generated
    virtual std::vector<std::string> &getTags() = 0;

    /// @brief The tags attribute.
    /// @return The values of the tags attribute.
    // @generated
    virtual const std::vector<std::string> &getTags() const = 0;

    /// @brief The levels attribute.
    /// @return The values of the levels attribute, which the caller can change.
    // @generated
    virtual std::vector<std::int32_t> &getLevels() = 0;

    /// @brief The levels attribute.
    /// @return The values of the levels attribute.
    // @generated
    virtual const std::vector<std::int32_t> &getLevels() const = 0;

    /// @brief The colour attribute.
    /// @return The current value of the colour attribute.
    // @generated
    virtual Colour getColour() const = 0;

    /// @brief Changes the colour attribute.
    /// @param value The new value.
    // @generated
    virtual void setColour(Colour value) = 0;

    /// @brief The description attribute.
    /// @return The current value of the description attribute.
    // @generated
    virtual const std::string &getDescription() const = 0;

    /// @brief Changes the description attribute.
    /// @param value The new value.
    // @generated
    virtual void setDescription(const std::string &value) = 0;

    /// @brief The canvas reference.
    /// @return The current value of the canvas reference.
    // @generated
    virtual std::shared_ptr<Canvas> getCanvas() const = 0;

    /// @brief Changes the canvas reference.
    /// @param value The new value.
    // @generated
    virtual void setCanvas(const std::shared_ptr<Canvas> &value) = 0;

protected:
    /// @brief Creates the part of an object that this class describes.
    // @generated
    Shape() = default;
};

}
