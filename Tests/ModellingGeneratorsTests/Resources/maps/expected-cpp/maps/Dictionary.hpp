#pragma once

//
//  Dictionary.hpp
//

#include "EObject.hpp"
#include "maps/MapsPackage.hpp"
#include <memory>
#include <vector>

// @generated
namespace maps { class StringToIntEntry; }

// @generated
namespace maps {

/// @brief The Dictionary class.
///
/// Part of the maps package.
// @generated
class Dictionary final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Dictionary class.
    // @generated
    const ClassInfo &eClass() const override { return MapsPackage::instance().dictionaryClass(); }

    /// @brief The entries reference.
    /// @return The values of the entries reference, which the caller can change.
    // @generated
    std::vector<std::shared_ptr<StringToIntEntry>> &getEntries() { return m_entries; }

    /// @brief The entries reference.
    /// @return The values of the entries reference.
    // @generated
    const std::vector<std::shared_ptr<StringToIntEntry>> &getEntries() const { return m_entries; }

private:
    /// @brief The storage of the entries reference.
    // @generated
    std::vector<std::shared_ptr<StringToIntEntry>> m_entries;
};

}
