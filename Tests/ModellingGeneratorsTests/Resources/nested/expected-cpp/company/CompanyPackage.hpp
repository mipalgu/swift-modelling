#pragma once

//
//  CompanyPackage.hpp
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace company {

/// @brief The description of the company package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class CompanyPackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const CompanyPackage &instance() {
        static const CompanyPackage description;
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

    /// @brief The description of the Company class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &companyClass() const { return m_info.classes[0]; }

private:
    /// @brief Builds the description of the package.
    // @generated
    CompanyPackage() {
        m_info.name = "company";
        m_info.nsURI = "http://swift-modelling.org/test/company";
        m_info.nsPrefix = "company";
        m_info.classes = {
            ClassInfo{"Company", false, {}, {
                FeatureInfo{"name", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"staff", FeatureKind::containment, true, "Employee"},
                FeatureInfo{"projects", FeatureKind::containment, true, "Project"},
            }},
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
