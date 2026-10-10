#pragma once

//
//  ProjPackage.hpp
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace company::projects {

/// @brief The description of the projects package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class ProjPackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const ProjPackage &instance() {
        static const ProjPackage description;
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

    /// @brief The description of the Project class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &projectClass() const { return m_info.classes[0]; }

private:
    /// @brief Builds the description of the package.
    // @generated
    ProjPackage() {
        m_info.name = "projects";
        m_info.nsURI = "http://swift-modelling.org/test/company/projects";
        m_info.nsPrefix = "projects";
        m_info.classes = {
            ClassInfo{"Project", false, {}, {
                FeatureInfo{"title", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"status", FeatureKind::attribute, false, "Status"},
                FeatureInfo{"members", FeatureKind::reference, true, "Employee"},
            }},
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
