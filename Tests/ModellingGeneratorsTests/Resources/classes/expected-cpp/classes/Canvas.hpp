#pragma once

//
//  Canvas.hpp
//

#include "EObject.hpp"
#include "classes/ClassesPackage.hpp"
#include <memory>
#include <vector>

// @generated
namespace classes { class Shape; }

// @generated
namespace classes {

/// @brief The Canvas class.
///
/// Part of the classes package.
// @generated
class Canvas final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Canvas class.
    // @generated
    const ClassInfo &eClass() const override { return ClassesPackage::instance().canvasClass(); }

    /// @brief The shapes reference.
    /// @return The values of the shapes reference, which the caller can change.
    // @generated
    std::vector<std::shared_ptr<Shape>> &getShapes() { return m_shapes; }

    /// @brief The shapes reference.
    /// @return The values of the shapes reference.
    // @generated
    const std::vector<std::shared_ptr<Shape>> &getShapes() const { return m_shapes; }

    /// @brief The background reference.
    /// @return The current value of the background reference.
    // @generated
    std::shared_ptr<Shape> getBackground() const { return m_background; }

    /// @brief Changes the background reference.
    /// @param value The new value.
    // @generated
    void setBackground(const std::shared_ptr<Shape> &value) { m_background = value; }

    /// @brief The favourites reference.
    /// @return The values of the favourites reference, which the caller can change.
    // @generated
    std::vector<std::weak_ptr<Shape>> &getFavourites() { return m_favourites; }

    /// @brief The favourites reference.
    /// @return The values of the favourites reference.
    // @generated
    const std::vector<std::weak_ptr<Shape>> &getFavourites() const { return m_favourites; }

    /// @brief The selected reference.
    /// @return The current value of the selected reference.
    // @generated
    std::shared_ptr<Shape> getSelected() const { return m_selected.lock(); }

    /// @brief Changes the selected reference.
    /// @param value The new value.
    // @generated
    void setSelected(const std::shared_ptr<Shape> &value) { m_selected = value; }

    /// @brief The primary reference.
    /// @return The current value of the primary reference.
    // @generated
    std::shared_ptr<Shape> getPrimary() const { return m_primary.lock(); }

    /// @brief Changes the primary reference.
    /// @param value The new value.
    // @generated
    void setPrimary(const std::shared_ptr<Shape> &value) { m_primary = value; }

private:
    /// @brief The storage of the shapes reference.
    // @generated
    std::vector<std::shared_ptr<Shape>> m_shapes;

    /// @brief The storage of the background reference.
    // @generated
    std::shared_ptr<Shape> m_background;

    /// @brief The storage of the favourites reference.
    // @generated
    std::vector<std::weak_ptr<Shape>> m_favourites;

    /// @brief The storage of the selected reference.
    // @generated
    std::weak_ptr<Shape> m_selected;

    /// @brief The storage of the primary reference.
    // @generated
    std::weak_ptr<Shape> m_primary;
};

}
