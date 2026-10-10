#pragma once

//
//  OrgPackage.hpp
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace organisation {

/// @brief The description of the organisation package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class OrgPackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const OrgPackage &instance() {
        static const OrgPackage description;
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

    /// @brief The description of the Person class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &personClass() const { return m_info.classes[0]; }

    /// @brief The description of the Team class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &teamClass() const { return m_info.classes[1]; }

    /// @brief The description of the Organisation class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &organisationClass() const { return m_info.classes[2]; }

private:
    /// @brief Builds the description of the package.
    // @generated
    OrgPackage() {
        m_info.name = "organisation";
        m_info.nsURI = "http://swift-modelling.org/test/organisation";
        m_info.nsPrefix = "org";
        m_info.classes = {
            ClassInfo{"Person", false, {}, {
                FeatureInfo{"name", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"age", FeatureKind::attribute, false, "EInt"},
            }},
            ClassInfo{"Team", false, {}, {
                FeatureInfo{"name", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"members", FeatureKind::containment, true, "Person"},
                FeatureInfo{"leader", FeatureKind::reference, false, "Person"},
            }},
            ClassInfo{"Organisation", false, {}, {
                FeatureInfo{"name", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"teams", FeatureKind::containment, true, "Team"},
            }},
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
