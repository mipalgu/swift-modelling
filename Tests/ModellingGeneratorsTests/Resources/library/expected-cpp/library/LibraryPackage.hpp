#pragma once

//
//  LibraryPackage.hpp
//
//  Copyright 2026 Example Pty Ltd
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace library {

/// @brief The description of the library package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class LibraryPackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const LibraryPackage &instance() {
        static const LibraryPackage description;
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

    /// @brief The description of the Named class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &namedClass() const { return m_info.classes[0]; }

    /// @brief The description of the Lendable class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &lendableClass() const { return m_info.classes[1]; }

    /// @brief The description of the Book class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &bookClass() const { return m_info.classes[2]; }

    /// @brief The description of the Writer class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &writerClass() const { return m_info.classes[3]; }

    /// @brief The description of the Library class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &libraryClass() const { return m_info.classes[4]; }

private:
    /// @brief Builds the description of the package.
    // @generated
    LibraryPackage() {
        m_info.name = "library";
        m_info.nsURI = "http://swift-modelling.org/test/library/1.0";
        m_info.nsPrefix = "lib";
        m_info.classes = {
            ClassInfo{"Named", true, {}, {
                FeatureInfo{"name", FeatureKind::attribute, false, "EString"},
            }},
            ClassInfo{"Lendable", true, {}, {
                FeatureInfo{"loanDays", FeatureKind::attribute, false, "EInt"},
                FeatureInfo{"onLoan", FeatureKind::attribute, false, "EBoolean"},
            }},
            ClassInfo{"Book", false, {"Named", "Lendable"}, {
                FeatureInfo{"name", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"loanDays", FeatureKind::attribute, false, "EInt"},
                FeatureInfo{"onLoan", FeatureKind::attribute, false, "EBoolean"},
                FeatureInfo{"pages", FeatureKind::attribute, false, "EInt"},
                FeatureInfo{"category", FeatureKind::attribute, false, "BookCategory"},
                FeatureInfo{"isbn", FeatureKind::attribute, false, "ISBN"},
                FeatureInfo{"author", FeatureKind::reference, false, "Writer"},
                FeatureInfo{"library", FeatureKind::reference, false, "Library"},
            }},
            ClassInfo{"Writer", false, {"Named"}, {
                FeatureInfo{"name", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"aliases", FeatureKind::attribute, true, "EString"},
                FeatureInfo{"books", FeatureKind::reference, true, "Book"},
            }},
            ClassInfo{"Library", false, {"Named"}, {
                FeatureInfo{"name", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"books", FeatureKind::containment, true, "Book"},
                FeatureInfo{"writers", FeatureKind::containment, true, "Writer"},
            }},
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
