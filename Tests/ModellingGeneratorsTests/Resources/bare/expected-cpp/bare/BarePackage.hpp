#pragma once

//
//  BarePackage.hpp
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace bare {

/// @brief The description of the bare package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class BarePackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const BarePackage &instance() {
        static const BarePackage description;
        return description;
    }

    /// @brief The name of the package.
    /// @return The name in the model.
    // @generated
    std::string_view name() const { return m_info.name; }

    /// @brief The namespace URI of the package.
    /// @return The namespace URI in the model.
    // @generated
    std::string_view nsURI() const { return m_info.nsURI; }

    /// @brief The namespace prefix of the package.
    /// @return The namespace prefix in the model.
    // @generated
    std::string_view nsPrefix() const { return m_info.nsPrefix; }

    /// @brief The description of the package and its classes.
    /// @return The description, which lives as long as the program.
    // @generated
    const PackageInfo &info() const { return m_info; }

    /// @brief The description of the Thing class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &thingClass() const { return m_info.classes[0]; }

private:
    /// @brief Builds the description of the package.
    // @generated
    BarePackage() {
        m_info.name = "bare";
        m_info.nsURI = "http://swift-modelling.org/test/bare";
        m_info.nsPrefix = "bare";
        m_info.classes = {
            ClassInfo{"Thing", false, {}, {
            }},
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
