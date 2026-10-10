#pragma once

//
//  FamiliesPackage.hpp
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace Families {

/// @brief The description of the Families package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class FamiliesPackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const FamiliesPackage &instance() {
        static const FamiliesPackage description;
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

    /// @brief The description of the Family class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &familyClass() const { return m_info.classes[0]; }

    /// @brief The description of the Member class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &memberClass() const { return m_info.classes[1]; }

private:
    /// @brief Builds the description of the package.
    // @generated
    FamiliesPackage() {
        m_info.name = "Families";
        m_info.nsURI = "http://www.example.org/families";
        m_info.nsPrefix = "families";
        m_info.classes = {
            ClassInfo{"Family", false, {}, {
                FeatureInfo{"lastName", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"father", FeatureKind::containment, false, "Member"},
                FeatureInfo{"mother", FeatureKind::containment, false, "Member"},
                FeatureInfo{"sons", FeatureKind::containment, true, "Member"},
                FeatureInfo{"daughters", FeatureKind::containment, true, "Member"},
            }},
            ClassInfo{"Member", false, {}, {
                FeatureInfo{"firstName", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"familyFather", FeatureKind::reference, false, "Family"},
                FeatureInfo{"familyMother", FeatureKind::reference, false, "Family"},
                FeatureInfo{"familySon", FeatureKind::reference, false, "Family"},
                FeatureInfo{"familyDaughter", FeatureKind::reference, false, "Family"},
            }},
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
