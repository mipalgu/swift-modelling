#pragma once

//
//  DocumentedPackage.hpp
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace documented {

/// @brief The description of the documented package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class DocumentedPackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const DocumentedPackage &instance() {
        static const DocumentedPackage description;
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

private:
    /// @brief Builds the description of the package.
    // @generated
    DocumentedPackage() {
        m_info.name = "documented";
        m_info.nsURI = "http://swift-modelling.org/test/documented";
        m_info.nsPrefix = "doc";
        m_info.classes = {
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
