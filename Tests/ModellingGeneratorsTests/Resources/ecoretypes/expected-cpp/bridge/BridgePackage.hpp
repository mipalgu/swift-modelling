#pragma once

//
//  BridgePackage.hpp
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace bridge {

/// @brief The description of the bridge package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class BridgePackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const BridgePackage &instance() {
        static const BridgePackage description;
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

    /// @brief The description of the Span class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &spanClass() const { return m_info.classes[0]; }

private:
    /// @brief Builds the description of the package.
    // @generated
    BridgePackage() {
        m_info.name = "bridge";
        m_info.nsURI = "http://swift-modelling.org/test/bridge";
        m_info.nsPrefix = "bridge";
        m_info.classes = {
            ClassInfo{"Span", false, {}, {
                FeatureInfo{"label", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"length", FeatureKind::attribute, false, "EDouble"},
                FeatureInfo{"payload", FeatureKind::attribute, false, "EJavaObject"},
                FeatureInfo{"supports", FeatureKind::reference, true, "EObject"},
                FeatureInfo{"next", FeatureKind::reference, false, "Span"},
            }},
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
