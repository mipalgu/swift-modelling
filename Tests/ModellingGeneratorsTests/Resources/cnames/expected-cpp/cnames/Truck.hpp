#pragma once

//
//  Truck.hpp
//

#include "EObject.hpp"
#include "cnames/CnamesPackage.hpp"
#include "cnames/Mode.hpp"
#include "cnames/Vehicle.hpp"
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

// @generated
namespace cnames { class Driver; }

// @generated
namespace cnames::delete_ { class Wheel; }

// @generated
namespace cnames { class static_; }

// @generated
namespace cnames {

/// @brief The Truck class.
///
/// Part of the cnames package.
// @generated
class Truck final : public virtual Vehicle {
public:
    /// @brief The description of the class of the object.
    /// @return The entry of the package description for the Truck class.
    // @generated
    const ClassInfo &eClass() const override { return CnamesPackage::instance().truckClass(); }

    /// @brief The int attribute.
    /// @return The current value of the int attribute.
    // @generated
    std::int32_t getInt() const override { return m_int; }

    /// @brief Changes the int attribute.
    /// @param value The new value.
    // @generated
    void setInt(std::int32_t value) override { m_int = value; }

    /// @brief The register attribute.
    /// @return The current value of the register attribute.
    // @generated
    const std::string &getRegister() const override { return m_register; }

    /// @brief Changes the register attribute.
    /// @param value The new value.
    // @generated
    void setRegister(const std::string &value) override { m_register = value; }

    /// @brief The union attribute.
    /// @return The current value of the union attribute.
    // @generated
    bool getUnion() const override { return m_union; }

    /// @brief Changes the union attribute.
    /// @param value The new value.
    // @generated
    void setUnion(bool value) override { m_union = value; }

    /// @brief The class attribute.
    /// @return The current value of the class attribute.
    // @generated
    const std::string &getClass() const override { return m_class; }

    /// @brief Changes the class attribute.
    /// @param value The new value.
    // @generated
    void setClass(const std::string &value) override { m_class = value; }

    /// @brief The namespace attribute.
    /// @return The current value of the namespace attribute.
    // @generated
    const std::string &getNamespace() const override { return m_namespace; }

    /// @brief Changes the namespace attribute.
    /// @param value The new value.
    // @generated
    void setNamespace(const std::string &value) override { m_namespace = value; }

    /// @brief The new attribute.
    /// @return The current value of the new attribute.
    // @generated
    std::int32_t getNew() const override { return m_new; }

    /// @brief Changes the new attribute.
    /// @param value The new value.
    // @generated
    void setNew(std::int32_t value) override { m_new = value; }

    /// @brief The delete attribute.
    /// @return The current value of the delete attribute.
    // @generated
    bool getDelete() const override { return m_delete; }

    /// @brief Changes the delete attribute.
    /// @param value The new value.
    // @generated
    void setDelete(bool value) override { m_delete = value; }

    /// @brief The template attribute.
    /// @return The current value of the template attribute.
    // @generated
    const std::string &getTemplate() const override { return m_template; }

    /// @brief Changes the template attribute.
    /// @param value The new value.
    // @generated
    void setTemplate(const std::string &value) override { m_template = value; }

    /// @brief The this attribute.
    /// @return The current value of the this attribute.
    // @generated
    const std::string &getThis() const override { return m_this; }

    /// @brief Changes the this attribute.
    /// @param value The new value.
    // @generated
    void setThis(const std::string &value) override { m_this = value; }

    /// @brief The signed attribute.
    /// @return The current value of the signed attribute.
    // @generated
    double getSigned() const override { return m_signed; }

    /// @brief Changes the signed attribute.
    /// @param value The new value.
    // @generated
    void setSigned(double value) override { m_signed = value; }

    /// @brief The NULL attribute.
    /// @return The current value of the NULL attribute.
    // @generated
    const std::string &getNULL() const override { return m_NULL; }

    /// @brief Changes the NULL attribute.
    /// @param value The new value.
    // @generated
    void setNULL(const std::string &value) override { m_NULL = value; }

    /// @brief The eObject attribute.
    /// @return The current value of the eObject attribute.
    // @generated
    const std::string &getEObject() const override { return m_eObject; }

    /// @brief Changes the eObject attribute.
    /// @param value The new value.
    // @generated
    void setEObject(const std::string &value) override { m_eObject = value; }

    /// @brief The bool attribute.
    /// @return The current value of the bool attribute.
    // @generated
    bool getBool() const override { return m_bool; }

    /// @brief Changes the bool attribute.
    /// @param value The new value.
    // @generated
    void setBool(bool value) override { m_bool = value; }

    /// @brief The default attribute.
    /// @return The current value of the default attribute.
    // @generated
    const std::string &getDefault() const override { return m_default; }

    /// @brief Changes the default attribute.
    /// @param value The new value.
    // @generated
    void setDefault(const std::string &value) override { m_default = value; }

    /// @brief The size_t attribute.
    /// @return The current value of the size_t attribute.
    // @generated
    std::int64_t getSize_t() const override { return m_size_t; }

    /// @brief Changes the size_t attribute.
    /// @param value The new value.
    // @generated
    void setSize_t(std::int64_t value) override { m_size_t = value; }

    /// @brief The mode attribute.
    /// @return The current value of the mode attribute.
    // @generated
    Mode getMode() const override { return m_mode; }

    /// @brief Changes the mode attribute.
    /// @param value The new value.
    // @generated
    void setMode(Mode value) override { m_mode = value; }

    /// @brief The modes attribute.
    /// @return The values of the modes attribute, which the caller can change.
    // @generated
    std::vector<Mode> &getModes() override { return m_modes; }

    /// @brief The modes attribute.
    /// @return The values of the modes attribute.
    // @generated
    const std::vector<Mode> &getModes() const override { return m_modes; }

    /// @brief The keywords attribute.
    /// @return The values of the keywords attribute, which the caller can change.
    // @generated
    std::vector<std::string> &getKeywords() override { return m_keywords; }

    /// @brief The keywords attribute.
    /// @return The values of the keywords attribute.
    // @generated
    const std::vector<std::string> &getKeywords() const override { return m_keywords; }

    /// @brief The driver reference.
    /// @return The current value of the driver reference.
    // @generated
    std::shared_ptr<Driver> getDriver() const override { return m_driver.lock(); }

    /// @brief Changes the driver reference.
    /// @param value The new value.
    // @generated
    void setDriver(const std::shared_ptr<Driver> &value) override { m_driver = value; }

    /// @brief The wheels reference.
    /// @return The values of the wheels reference, which the caller can change.
    // @generated
    std::vector<std::shared_ptr<::cnames::delete_::Wheel>> &getWheels() override { return m_wheels; }

    /// @brief The wheels reference.
    /// @return The values of the wheels reference.
    // @generated
    const std::vector<std::shared_ptr<::cnames::delete_::Wheel>> &getWheels() const override { return m_wheels; }

    /// @brief The static reference.
    /// @return The current value of the static reference.
    // @generated
    std::shared_ptr<static_> getStatic() const override { return m_static.lock(); }

    /// @brief Changes the static reference.
    /// @param value The new value.
    // @generated
    void setStatic(const std::shared_ptr<static_> &value) override { m_static = value; }

    /// @brief The operator attribute.
    /// @return The current value of the operator attribute.
    // @generated
    std::int32_t getOperator() const { return m_operator; }

    /// @brief Changes the operator attribute.
    /// @param value The new value.
    // @generated
    void setOperator(std::int32_t value) { m_operator = value; }

    /// @brief The goto attribute.
    /// @return The current value of the goto attribute.
    // @generated
    const std::string &getGoto() const { return m_goto; }

    /// @brief Changes the goto attribute.
    /// @param value The new value.
    // @generated
    void setGoto(const std::string &value) { m_goto = value; }

    /// @brief The trailer reference.
    /// @return The current value of the trailer reference.
    // @generated
    std::shared_ptr<Truck> getTrailer() const { return m_trailer.lock(); }

    /// @brief Changes the trailer reference.
    /// @param value The new value.
    // @generated
    void setTrailer(const std::shared_ptr<Truck> &value) { m_trailer = value; }

    /// @brief The towedBy reference.
    /// @return The current value of the towedBy reference.
    // @generated
    std::shared_ptr<Truck> getTowedBy() const { return m_towedBy.lock(); }

    /// @brief Changes the towedBy reference.
    /// @param value The new value.
    // @generated
    void setTowedBy(const std::shared_ptr<Truck> &value) { m_towedBy = value; }

private:
    /// @brief The storage of the int attribute.
    // @generated
    std::int32_t m_int = 0;

    /// @brief The storage of the register attribute.
    // @generated
    std::string m_register;

    /// @brief The storage of the union attribute.
    // @generated
    bool m_union = false;

    /// @brief The storage of the class attribute.
    // @generated
    std::string m_class;

    /// @brief The storage of the namespace attribute.
    // @generated
    std::string m_namespace;

    /// @brief The storage of the new attribute.
    // @generated
    std::int32_t m_new = 0;

    /// @brief The storage of the delete attribute.
    // @generated
    bool m_delete = false;

    /// @brief The storage of the template attribute.
    // @generated
    std::string m_template;

    /// @brief The storage of the this attribute.
    // @generated
    std::string m_this;

    /// @brief The storage of the signed attribute.
    // @generated
    double m_signed = 1.5;

    /// @brief The storage of the NULL attribute.
    // @generated
    std::string m_NULL;

    /// @brief The storage of the eObject attribute.
    // @generated
    std::string m_eObject;

    /// @brief The storage of the bool attribute.
    // @generated
    bool m_bool = true;

    /// @brief The storage of the default attribute.
    // @generated
    std::string m_default = "say \"hi\"\n\\there";

    /// @brief The storage of the size_t attribute.
    // @generated
    std::int64_t m_size_t = 0;

    /// @brief The storage of the mode attribute.
    // @generated
    Mode m_mode = Mode::and_;

    /// @brief The storage of the modes attribute.
    // @generated
    std::vector<Mode> m_modes;

    /// @brief The storage of the keywords attribute.
    // @generated
    std::vector<std::string> m_keywords;

    /// @brief The storage of the driver reference.
    // @generated
    std::weak_ptr<Driver> m_driver;

    /// @brief The storage of the wheels reference.
    // @generated
    std::vector<std::shared_ptr<::cnames::delete_::Wheel>> m_wheels;

    /// @brief The storage of the static reference.
    // @generated
    std::weak_ptr<static_> m_static;

    /// @brief The storage of the operator attribute.
    // @generated
    std::int32_t m_operator = 0;

    /// @brief The storage of the goto attribute.
    // @generated
    std::string m_goto = "N/A";

    /// @brief The storage of the trailer reference.
    // @generated
    std::weak_ptr<Truck> m_trailer;

    /// @brief The storage of the towedBy reference.
    // @generated
    std::weak_ptr<Truck> m_towedBy;
};

}
