/**
 */
package org.example.company.company.projects;


import org.eclipse.emf.common.util.EList;

import org.eclipse.emf.ecore.EObject;

import org.example.company.company.people.Employee;


/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Project</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link org.example.company.company.projects.Project#getTitle <em>Title</em>}</li>
 *   <li>{@link org.example.company.company.projects.Project#getStatus <em>Status</em>}</li>
 *   <li>{@link org.example.company.company.projects.Project#getMembers <em>Members</em>}</li>
 * </ul>
 *
 * @see org.example.company.company.projects.ProjPackage#getProject()
 * @model
 * @generated
 */
public interface Project extends EObject
{
  /**
   * Returns the value of the '<em><b>Title</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Title</em>' attribute.
   * @see #setTitle(String)
   * @see org.example.company.company.projects.ProjPackage#getProject_Title()
   * @model
   * @generated
   */
  String getTitle();

  /**
   * Sets the value of the '{@link org.example.company.company.projects.Project#getTitle <em>Title</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Title</em>' attribute.
   * @see #getTitle()
   * @generated
   */
  void setTitle(String value);

  /**
   * Returns the value of the '<em><b>Status</b></em>' attribute.
   * The literals are from the enumeration {@link org.example.company.company.projects.Status}.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Status</em>' attribute.
   * @see org.example.company.company.projects.Status
   * @see #setStatus(Status)
   * @see org.example.company.company.projects.ProjPackage#getProject_Status()
   * @model
   * @generated
   */
  Status getStatus();

  /**
   * Sets the value of the '{@link org.example.company.company.projects.Project#getStatus <em>Status</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Status</em>' attribute.
   * @see org.example.company.company.projects.Status
   * @see #getStatus()
   * @generated
   */
  void setStatus(Status value);

  /**
   * Returns the value of the '<em><b>Members</b></em>' reference list.
   * The list contents are of type {@link org.example.company.company.people.Employee}.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Members</em>' reference list.
   * @see org.example.company.company.projects.ProjPackage#getProject_Members()
   * @model
   * @generated
   */
  EList<Employee> getMembers();

} // Project
