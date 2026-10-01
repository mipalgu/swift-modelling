/**
 */
package org.example.company.company;


import org.eclipse.emf.common.util.EList;

import org.eclipse.emf.ecore.EObject;

import org.example.company.company.people.Employee;

import org.example.company.company.projects.Project;


/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Company</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link org.example.company.company.Company#getName <em>Name</em>}</li>
 *   <li>{@link org.example.company.company.Company#getStaff <em>Staff</em>}</li>
 *   <li>{@link org.example.company.company.Company#getProjects <em>Projects</em>}</li>
 * </ul>
 *
 * @see org.example.company.company.CompanyPackage#getCompany()
 * @model
 * @generated
 */
public interface Company extends EObject
{
  /**
   * Returns the value of the '<em><b>Name</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Name</em>' attribute.
   * @see #setName(String)
   * @see org.example.company.company.CompanyPackage#getCompany_Name()
   * @model
   * @generated
   */
  String getName();

  /**
   * Sets the value of the '{@link org.example.company.company.Company#getName <em>Name</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Name</em>' attribute.
   * @see #getName()
   * @generated
   */
  void setName(String value);

  /**
   * Returns the value of the '<em><b>Staff</b></em>' containment reference list.
   * The list contents are of type {@link org.example.company.company.people.Employee}.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Staff</em>' containment reference list.
   * @see org.example.company.company.CompanyPackage#getCompany_Staff()
   * @model containment="true"
   * @generated
   */
  EList<Employee> getStaff();

  /**
   * Returns the value of the '<em><b>Projects</b></em>' containment reference list.
   * The list contents are of type {@link org.example.company.company.projects.Project}.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Projects</em>' containment reference list.
   * @see org.example.company.company.CompanyPackage#getCompany_Projects()
   * @model containment="true"
   * @generated
   */
  EList<Project> getProjects();

} // Company
