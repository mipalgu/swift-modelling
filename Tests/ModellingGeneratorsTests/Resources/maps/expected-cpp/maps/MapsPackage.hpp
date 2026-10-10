#pragma once

//
//  MapsPackage.hpp
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace maps {

/// @brief The description of the maps package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class MapsPackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const MapsPackage &instance() {
        static const MapsPackage description;
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

    /// @brief The description of the Dictionary class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &dictionaryClass() const { return m_info.classes[0]; }

    /// @brief The description of the StringToIntEntry class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &stringToIntEntryClass() const { return m_info.classes[1]; }

private:
    /// @brief Builds the description of the package.
    // @generated
    MapsPackage() {
        m_info.name = "maps";
        m_info.nsURI = "http://swift-modelling.org/test/maps";
        m_info.nsPrefix = "maps";
        m_info.classes = {
            ClassInfo{"Dictionary", false, {}, {
                FeatureInfo{"entries", FeatureKind::containment, true, "StringToIntEntry"},
            }},
            ClassInfo{"StringToIntEntry", false, {}, {
                FeatureInfo{"key", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"value", FeatureKind::attribute, false, "EInt"},
            }},
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
