#pragma once

//
//  Circle.hpp
//

#include "EObject.hpp"
#include "classes/ClassesPackage.hpp"
#include "classes/Colour.hpp"
#include "classes/Named.hpp"
#include "classes/Shape.hpp"
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

// @generated
namespace classes { class Canvas; }

// @generated
namespace classes {

/// @brief The Circle class.
///
/// Part of the classes package.
// @generated
class Circle final : public virtual Shape, public virtual Named {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Circle class.
    // @generated
    const ClassInfo &eClass() const override { return ClassesPackage::instance().circleClass(); }

    /// @brief The label of the shape.
    /// @return The current value of the label attribute.
    // @generated
    const std::string &getLabel() const override { return m_label; }

    /// @brief Changes the label attribute.
    /// @param value The new value.
    // @generated
    void setLabel(const std::string &value) override { m_label = value; }

    /// @brief The visible attribute.
    /// @return The current value of the visible attribute.
    // @generated
    bool getVisible() const override { return m_visible; }

    /// @brief Changes the visible attribute.
    /// @param value The new value.
    // @generated
    void setVisible(bool value) override { m_visible = value; }

    /// @brief The weight attribute.
    /// @return The current value of the weight attribute.
    // @generated
    double getWeight() const override { return m_weight; }

    /// @brief Changes the weight attribute.
    /// @param value The new value.
    // @generated
    void setWeight(double value) override { m_weight = value; }

    /// @brief The tags attribute.
    /// @return The values of the tags attribute, which the caller can change.
    // @generated
    std::vector<std::string> &getTags() override { return m_tags; }

    /// @brief The tags attribute.
    /// @return The values of the tags attribute.
    // @generated
    const std::vector<std::string> &getTags() const override { return m_tags; }

    /// @brief The levels attribute.
    /// @return The values of the levels attribute, which the caller can change.
    // @generated
    std::vector<std::int32_t> &getLevels() override { return m_levels; }

    /// @brief The levels attribute.
    /// @return The values of the levels attribute.
    // @generated
    const std::vector<std::int32_t> &getLevels() const override { return m_levels; }

    /// @brief The colour attribute.
    /// @return The current value of the colour attribute.
    // @generated
    Colour getColour() const override { return m_colour; }

    /// @brief Changes the colour attribute.
    /// @param value The new value.
    // @generated
    void setColour(Colour value) override { m_colour = value; }

    /// @brief The description attribute.
    /// @return The current value of the description attribute.
    // @generated
    const std::string &getDescription() const override { return m_description; }

    /// @brief Changes the description attribute.
    /// @param value The new value.
    // @generated
    void setDescription(const std::string &value) override { m_description = value; }

    /// @brief The canvas reference.
    /// @return The current value of the canvas reference.
    // @generated
    std::shared_ptr<Canvas> getCanvas() const override { return m_canvas.lock(); }

    /// @brief Changes the canvas reference.
    /// @param value The new value.
    // @generated
    void setCanvas(const std::shared_ptr<Canvas> &value) override { m_canvas = value; }

    /// @brief The name attribute.
    /// @return The current value of the name attribute.
    // @generated
    const std::string &getName() const override { return m_name; }

    /// @brief Changes the name attribute.
    /// @param value The new value.
    // @generated
    void setName(const std::string &value) override { m_name = value; }

    /// @brief The radius attribute.
    /// @return The current value of the radius attribute.
    // @generated
    double getRadius() const { return m_radius; }

    /// @brief Changes the radius attribute.
    /// @param value The new value.
    // @generated
    void setRadius(double value) { m_radius = value; }

    /// @brief The filled attribute.
    /// @return The current value of the filled attribute.
    // @generated
    bool getFilled() const { return m_filled; }

    /// @brief Changes the filled attribute.
    /// @param value The new value.
    // @generated
    void setFilled(bool value) { m_filled = value; }

private:
    /// @brief The storage of the label attribute.
    // @generated
    std::string m_label;

    /// @brief The storage of the visible attribute.
    // @generated
    bool m_visible = true;

    /// @brief The storage of the weight attribute.
    // @generated
    double m_weight = 1.5;

    /// @brief The storage of the tags attribute.
    // @generated
    std::vector<std::string> m_tags;

    /// @brief The storage of the levels attribute.
    // @generated
    std::vector<std::int32_t> m_levels;

    /// @brief The storage of the colour attribute.
    // @generated
    Colour m_colour = Colour::Green;

    /// @brief The storage of the description attribute.
    // @generated
    std::string m_description;

    /// @brief The storage of the canvas reference.
    // @generated
    std::weak_ptr<Canvas> m_canvas;

    /// @brief The storage of the name attribute.
    // @generated
    std::string m_name;

    /// @brief The storage of the radius attribute.
    // @generated
    double m_radius = 0.0;

    /// @brief The storage of the filled attribute.
    // @generated
    bool m_filled = false;
};

}
