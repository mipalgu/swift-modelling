#pragma once

//
//  ClassesPackage.hpp
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace classes {

/// @brief The description of the classes package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class ClassesPackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const ClassesPackage &instance() {
        static const ClassesPackage description;
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

    /// @brief The description of the Shape class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &shapeClass() const { return m_info.classes[0]; }

    /// @brief The description of the Canvas class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &canvasClass() const { return m_info.classes[1]; }

    /// @brief The description of the Named class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &namedClass() const { return m_info.classes[2]; }

    /// @brief The description of the Circle class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &circleClass() const { return m_info.classes[3]; }

private:
    /// @brief Builds the description of the package.
    // @generated
    ClassesPackage() {
        m_info.name = "classes";
        m_info.nsURI = "http://swift-modelling.org/test/classes";
        m_info.nsPrefix = "cls";
        m_info.classes = {
            ClassInfo{"Shape", true, {}, {
                FeatureInfo{"label", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"visible", FeatureKind::attribute, false, "EBoolean"},
                FeatureInfo{"weight", FeatureKind::attribute, false, "EDouble"},
                FeatureInfo{"tags", FeatureKind::attribute, true, "EString"},
                FeatureInfo{"levels", FeatureKind::attribute, true, "EInt"},
                FeatureInfo{"colour", FeatureKind::attribute, false, "Colour"},
                FeatureInfo{"description", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"canvas", FeatureKind::reference, false, "Canvas"},
            }},
            ClassInfo{"Canvas", false, {}, {
                FeatureInfo{"shapes", FeatureKind::containment, true, "Shape"},
                FeatureInfo{"background", FeatureKind::containment, false, "Shape"},
                FeatureInfo{"favourites", FeatureKind::reference, true, "Shape"},
                FeatureInfo{"selected", FeatureKind::reference, false, "Shape"},
                FeatureInfo{"primary", FeatureKind::reference, false, "Shape"},
            }},
            ClassInfo{"Named", true, {}, {
                FeatureInfo{"name", FeatureKind::attribute, false, "EString"},
            }},
            ClassInfo{"Circle", false, {"Shape", "Named"}, {
                FeatureInfo{"label", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"visible", FeatureKind::attribute, false, "EBoolean"},
                FeatureInfo{"weight", FeatureKind::attribute, false, "EDouble"},
                FeatureInfo{"tags", FeatureKind::attribute, true, "EString"},
                FeatureInfo{"levels", FeatureKind::attribute, true, "EInt"},
                FeatureInfo{"colour", FeatureKind::attribute, false, "Colour"},
                FeatureInfo{"description", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"canvas", FeatureKind::reference, false, "Canvas"},
                FeatureInfo{"name", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"radius", FeatureKind::attribute, false, "EDouble"},
                FeatureInfo{"filled", FeatureKind::attribute, false, "EBoolean"},
            }},
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
