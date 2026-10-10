#pragma once

//
//  DeletePackage.hpp
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace cnames::delete_ {

/// @brief The description of the delete package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class DeletePackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const DeletePackage &instance() {
        static const DeletePackage description;
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

    /// @brief The description of the Wheel class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &wheelClass() const { return m_info.classes[0]; }

private:
    /// @brief Builds the description of the package.
    // @generated
    DeletePackage() {
        m_info.name = "delete";
        m_info.nsURI = "http://swift-modelling.org/test/cnames/delete";
        m_info.nsPrefix = "del";
        m_info.classes = {
            ClassInfo{"Wheel", false, {}, {
                FeatureInfo{"auto", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"virtual", FeatureKind::reference, false, "Vehicle"},
            }},
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
