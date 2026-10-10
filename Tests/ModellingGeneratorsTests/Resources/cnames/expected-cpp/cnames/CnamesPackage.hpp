#pragma once

//
//  CnamesPackage.hpp
//

#include "EObject.hpp"
#include <string_view>

// @generated
namespace cnames {

/// @brief The description of the cnames package.
///
/// The shared instance holds the description of the package and of each of its classes, which the objects of the
/// package return as their class.
// @generated
class CnamesPackage final {
public:
    /// @brief The shared description of the package.
    /// @return The only instance.
    // @generated
    static const CnamesPackage &instance() {
        static const CnamesPackage description;
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

    /// @brief The description of the Vehicle class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &vehicleClass() const { return m_info.classes[0]; }

    /// @brief The description of the Truck class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &truckClass() const { return m_info.classes[1]; }

    /// @brief The description of the Driver class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &driverClass() const { return m_info.classes[2]; }

    /// @brief The description of the static class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &staticClass() const { return m_info.classes[3]; }

    /// @brief The description of the FILE class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &fILEClass() const { return m_info.classes[4]; }

    /// @brief The description of the EObject class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &eObjectClass() const { return m_info.classes[5]; }

    /// @brief The description of the Shape class.
    /// @return The description, which lives as long as the program.
    // @generated
    const ClassInfo &shapeClass() const { return m_info.classes[6]; }

private:
    /// @brief Builds the description of the package.
    // @generated
    CnamesPackage() {
        m_info.name = "cnames";
        m_info.nsURI = "http://swift-modelling.org/test/cnames";
        m_info.nsPrefix = "cn";
        m_info.classes = {
            ClassInfo{"Vehicle", false, {}, {
                FeatureInfo{"int", FeatureKind::attribute, false, "EInt"},
                FeatureInfo{"register", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"union", FeatureKind::attribute, false, "EBoolean"},
                FeatureInfo{"class", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"namespace", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"new", FeatureKind::attribute, false, "EInt"},
                FeatureInfo{"delete", FeatureKind::attribute, false, "EBoolean"},
                FeatureInfo{"template", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"this", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"signed", FeatureKind::attribute, false, "EDouble"},
                FeatureInfo{"NULL", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"eObject", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"bool", FeatureKind::attribute, false, "EBoolean"},
                FeatureInfo{"default", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"size_t", FeatureKind::attribute, false, "ELong"},
                FeatureInfo{"mode", FeatureKind::attribute, false, "Mode"},
                FeatureInfo{"modes", FeatureKind::attribute, true, "Mode"},
                FeatureInfo{"keywords", FeatureKind::attribute, true, "EString"},
                FeatureInfo{"driver", FeatureKind::reference, false, "Driver"},
                FeatureInfo{"wheels", FeatureKind::containment, true, "Wheel"},
                FeatureInfo{"static", FeatureKind::reference, false, "static"},
            }},
            ClassInfo{"Truck", false, {"Vehicle"}, {
                FeatureInfo{"int", FeatureKind::attribute, false, "EInt"},
                FeatureInfo{"register", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"union", FeatureKind::attribute, false, "EBoolean"},
                FeatureInfo{"class", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"namespace", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"new", FeatureKind::attribute, false, "EInt"},
                FeatureInfo{"delete", FeatureKind::attribute, false, "EBoolean"},
                FeatureInfo{"template", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"this", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"signed", FeatureKind::attribute, false, "EDouble"},
                FeatureInfo{"NULL", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"eObject", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"bool", FeatureKind::attribute, false, "EBoolean"},
                FeatureInfo{"default", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"size_t", FeatureKind::attribute, false, "ELong"},
                FeatureInfo{"mode", FeatureKind::attribute, false, "Mode"},
                FeatureInfo{"modes", FeatureKind::attribute, true, "Mode"},
                FeatureInfo{"keywords", FeatureKind::attribute, true, "EString"},
                FeatureInfo{"driver", FeatureKind::reference, false, "Driver"},
                FeatureInfo{"wheels", FeatureKind::containment, true, "Wheel"},
                FeatureInfo{"static", FeatureKind::reference, false, "static"},
                FeatureInfo{"operator", FeatureKind::attribute, false, "EInt"},
                FeatureInfo{"goto", FeatureKind::attribute, false, "EString"},
                FeatureInfo{"trailer", FeatureKind::reference, false, "Truck"},
                FeatureInfo{"towedBy", FeatureKind::reference, false, "Truck"},
            }},
            ClassInfo{"Driver", false, {}, {
                FeatureInfo{"vehicle", FeatureKind::reference, false, "Vehicle"},
            }},
            ClassInfo{"static", false, {}, {
                FeatureInfo{"volatile", FeatureKind::attribute, false, "EBoolean"},
            }},
            ClassInfo{"FILE", false, {}, {
            }},
            ClassInfo{"EObject", false, {}, {
                FeatureInfo{"eClass", FeatureKind::attribute, false, "EString"},
            }},
            ClassInfo{"Shape", true, {}, {
            }},
        };
    }

    /// @brief The description of the package and its classes.
    // @generated
    PackageInfo m_info;
};

}
