/**
 */
package org.example.company.company.projects.impl;


import java.util.Collection;

import org.eclipse.emf.common.notify.Notification;

import org.eclipse.emf.common.util.EList;

import org.eclipse.emf.ecore.EClass;

import org.eclipse.emf.ecore.impl.ENotificationImpl;
import org.eclipse.emf.ecore.impl.EObjectImpl;

import org.eclipse.emf.ecore.util.EObjectResolvingEList;

import org.example.company.company.people.Employee;

import org.example.company.company.projects.ProjPackage;
import org.example.company.company.projects.Project;
import org.example.company.company.projects.Status;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>Project</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 *   <li>{@link org.example.company.company.projects.impl.ProjectImpl#getTitle <em>Title</em>}</li>
 *   <li>{@link org.example.company.company.projects.impl.ProjectImpl#getStatus <em>Status</em>}</li>
 *   <li>{@link org.example.company.company.projects.impl.ProjectImpl#getMembers <em>Members</em>}</li>
 * </ul>
 *
 * @generated
 */
public class ProjectImpl extends EObjectImpl implements Project
{
  /**
   * The default value of the '{@link #getTitle() <em>Title</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getTitle()
   * @generated
   * @ordered
   */
  protected static final String TITLE_EDEFAULT = null;

  /**
   * The cached value of the '{@link #getTitle() <em>Title</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getTitle()
   * @generated
   * @ordered
   */
  protected String title = TITLE_EDEFAULT;

  /**
   * The default value of the '{@link #getStatus() <em>Status</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getStatus()
   * @generated
   * @ordered
   */
  protected static final Status STATUS_EDEFAULT = Status.PROPOSED;

  /**
   * The cached value of the '{@link #getStatus() <em>Status</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getStatus()
   * @generated
   * @ordered
   */
  protected Status status = STATUS_EDEFAULT;

  /**
   * The cached value of the '{@link #getMembers() <em>Members</em>}' reference list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getMembers()
   * @generated
   * @ordered
   */
  protected EList<Employee> members;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  protected ProjectImpl()
  {
    super();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  protected EClass eStaticClass()
  {
    return ProjPackage.Literals.PROJECT;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public String getTitle()
  {
    return title;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setTitle(String newTitle)
  {
    String oldTitle = title;
    title = newTitle;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, ProjPackage.PROJECT__TITLE, oldTitle, title));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Status getStatus()
  {
    return status;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setStatus(Status newStatus)
  {
    Status oldStatus = status;
    status = newStatus == null ? STATUS_EDEFAULT : newStatus;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, ProjPackage.PROJECT__STATUS, oldStatus, status));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EList<Employee> getMembers()
  {
    if (members == null)
    {
      members = new EObjectResolvingEList<Employee>(Employee.class, this, ProjPackage.PROJECT__MEMBERS);
    }
    return members;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Object eGet(int featureID, boolean resolve, boolean coreType)
  {
    switch (featureID)
    {
      case ProjPackage.PROJECT__TITLE:
        return getTitle();
      case ProjPackage.PROJECT__STATUS:
        return getStatus();
      case ProjPackage.PROJECT__MEMBERS:
        return getMembers();
    }
    return super.eGet(featureID, resolve, coreType);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @SuppressWarnings("unchecked")
  @Override
  public void eSet(int featureID, Object newValue)
  {
    switch (featureID)
    {
      case ProjPackage.PROJECT__TITLE:
        setTitle((String)newValue);
        return;
      case ProjPackage.PROJECT__STATUS:
        setStatus((Status)newValue);
        return;
      case ProjPackage.PROJECT__MEMBERS:
        getMembers().clear();
        getMembers().addAll((Collection<? extends Employee>)newValue);
        return;
    }
    super.eSet(featureID, newValue);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void eUnset(int featureID)
  {
    switch (featureID)
    {
      case ProjPackage.PROJECT__TITLE:
        setTitle(TITLE_EDEFAULT);
        return;
      case ProjPackage.PROJECT__STATUS:
        setStatus(STATUS_EDEFAULT);
        return;
      case ProjPackage.PROJECT__MEMBERS:
        getMembers().clear();
        return;
    }
    super.eUnset(featureID);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public boolean eIsSet(int featureID)
  {
    switch (featureID)
    {
      case ProjPackage.PROJECT__TITLE:
        return TITLE_EDEFAULT == null ? title != null : !TITLE_EDEFAULT.equals(title);
      case ProjPackage.PROJECT__STATUS:
        return status != STATUS_EDEFAULT;
      case ProjPackage.PROJECT__MEMBERS:
        return members != null && !members.isEmpty();
    }
    return super.eIsSet(featureID);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public String toString()
  {
    if (eIsProxy()) return super.toString();

    StringBuilder result = new StringBuilder(super.toString());
    result.append(" (title: ");
    result.append(title);
    result.append(", status: ");
    result.append(status);
    result.append(')');
    return result.toString();
  }

} //ProjectImpl
