#pragma once

//
//  ArchivePackage.hpp
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace company::projects::archive {

/// @brief The description of the archive package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class ArchivePackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const ArchivePackage &instance() {
        static const ArchivePackage description;
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

    /// @brief The description of the Record class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &recordClass() const { return m_info.classes[0]; }

private:
    /// @brief Builds the description of the package.
    // @generated
    ArchivePackage() {
        m_info.name = "archive";
        m_info.nsURI = "http://swift-modelling.org/test/company/projects/archive";
        m_info.nsPrefix = "archive";
        m_info.classes = {
            ClassInfo{"Record", false, {}, {
                FeatureInfo{"project", FeatureKind::reference, false, "Project"},
            }},
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
