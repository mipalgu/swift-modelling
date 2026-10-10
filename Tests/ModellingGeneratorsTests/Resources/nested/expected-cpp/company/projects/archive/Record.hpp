#pragma once

//
//  Record.hpp
//

#include "EObject.hpp"
#include "company/projects/archive/ArchivePackage.hpp"
#include <memory>

// @generated
namespace company::projects { class Project; }

// @generated
namespace company::projects::archive {

/// @brief The Record class.
///
/// Part of the archive package.
// @generated
class Record final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Record class.
    // @generated
    const ClassInfo &eClass() const override { return ArchivePackage::instance().recordClass(); }

    /// @brief The project reference.
    /// @return The current value of the project reference.
    // @generated
    std::shared_ptr<::company::projects::Project> getProject() const { return m_project.lock(); }

    /// @brief Changes the project reference.
    /// @param value The new value.
    // @generated
    void setProject(const std::shared_ptr<::company::projects::Project> &value) { m_project = value; }

private:
    /// @brief The storage of the project reference.
    // @generated
    std::weak_ptr<::company::projects::Project> m_project;
};

}
