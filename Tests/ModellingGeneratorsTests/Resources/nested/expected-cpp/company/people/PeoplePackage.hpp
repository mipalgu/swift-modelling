#pragma once

//
//  PeoplePackage.hpp
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace company::people {

/// @brief The description of the people package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class PeoplePackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const PeoplePackage &instance() {
        static const PeoplePackage description;
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

    /// @brief The description of the Employee class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &employeeClass() const { return m_info.classes[1]; }

private:
    /// @brief Builds the description of the package.
    // @generated
    PeoplePackage() {
        m_info.name = "people";
        m_info.nsURI = "http://swift-modelling.org/test/company/people";
        m_info.nsPrefix = "people";
        m_info.classes = {
            ClassInfo{"Person", true, {}, {
                FeatureInfo{"name", FeatureKind::attribute, false, "EString"},
            }},
            ClassInfo{"Employee", false, {"Person"}, {
                FeatureInfo{"name", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"salary", FeatureKind::attribute, false, "EDouble"},
            }},
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
