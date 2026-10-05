/**
 */
package org.example.company.company.people;


/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Employee</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link org.example.company.company.people.Employee#getSalary <em>Salary</em>}</li>
 * </ul>
 *
 * @see org.example.company.company.people.PeoplePackage#getEmployee()
 * @model
 * @generated
 */
public interface Employee extends Person {
	/**
	 * Returns the value of the '<em><b>Salary</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Salary</em>' attribute.
	 * @see #setSalary(double)
	 * @see org.example.company.company.people.PeoplePackage#getEmployee_Salary()
	 * @model
	 * @generated
	 */
	double getSalary();

	/**
	 * Sets the value of the '{@link org.example.company.company.people.Employee#getSalary <em>Salary</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Salary</em>' attribute.
	 * @see #getSalary()
	 * @generated
	 */
	void setSalary(double value);

} // Employee
