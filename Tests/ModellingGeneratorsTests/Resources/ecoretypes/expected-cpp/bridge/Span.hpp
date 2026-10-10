#pragma once

//
//  Span.hpp
//

#include "EObject.hpp"
#include "bridge/BridgePackage.hpp"
#include <any>
#include <memory>
#include <string>
#include <vector>

// @generated
namespace bridge {

/// @brief The Span class.
///
/// Part of the bridge package.
// @generated
class Span final : public virtual EObject {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Span class.
    // @generated
    const ClassInfo &eClass() const override { return BridgePackage::instance().spanClass(); }

    /// @brief The label attribute.
    /// @return The current value of the label attribute.
    // @generated
    const std::string &getLabel() const { return m_label; }

    /// @brief Changes the label attribute.
    /// @param value The new value.
    // @generated
    void setLabel(const std::string &value) { m_label = value; }

    /// @brief The length attribute.
    /// @return The current value of the length attribute.
    // @generated
    double getLength() const { return m_length; }

    /// @brief Changes the length attribute.
    /// @param value The new value.
    // @generated
    void setLength(double value) { m_length = value; }

    /// @brief The payload attribute.
    /// @return The current value of the payload attribute.
    // @generated
    const std::any &getPayload() const { return m_payload; }

    /// @brief Changes the payload attribute.
    /// @param value The new value.
    // @generated
    void setPayload(const std::any &value) { m_payload = value; }

    /// @brief The supports reference.
    /// @return The values of the supports reference, which the caller can change.
    // @generated
    std::vector<std::shared_ptr<EObject>> &getSupports() { return m_supports; }

    /// @brief The supports reference.
    /// @return The values of the supports reference.
    // @generated
    const std::vector<std::shared_ptr<EObject>> &getSupports() const { return m_supports; }

    /// @brief The next reference.
    /// @return The current value of the next reference.
    // @generated
    std::shared_ptr<Span> getNext() const { return m_next.lock(); }

    /// @brief Changes the next reference.
    /// @param value The new value.
    // @generated
    void setNext(const std::shared_ptr<Span> &value) { m_next = value; }

private:
    /// @brief The storage of the label attribute.
    // @generated
    std::string m_label;

    /// @brief The storage of the length attribute.
    // @generated
    double m_length = 0.0;

    /// @brief The storage of the payload attribute.
    // @generated
    std::any m_payload;

    /// @brief The storage of the supports reference.
    // @generated
    std::vector<std::shared_ptr<EObject>> m_supports;

    /// @brief The storage of the next reference.
    // @generated
    std::weak_ptr<Span> m_next;
};

}
