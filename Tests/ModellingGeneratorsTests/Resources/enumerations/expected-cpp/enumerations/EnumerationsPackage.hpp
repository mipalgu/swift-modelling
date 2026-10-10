#pragma once

//
//  EnumerationsPackage.hpp
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace enumerations {

/// @brief The description of the enumerations package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class EnumerationsPackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const EnumerationsPackage &instance() {
        static const EnumerationsPackage description;
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

    /// @brief The description of the Light class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &lightClass() const { return m_info.classes[0]; }

private:
    /// @brief Builds the description of the package.
    // @generated
    EnumerationsPackage() {
        m_info.name = "enumerations";
        m_info.nsURI = "http://swift-modelling.org/test/enumerations";
        m_info.nsPrefix = "enums";
        m_info.classes = {
            ClassInfo{"Light", false, {}, {
                FeatureInfo{"colour", FeatureKind::attribute, false, "Colour"},
                FeatureInfo{"mode", FeatureKind::attribute, false, "Mode"},
            }},
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
