/**
 */
package org.example.company.company.projects.archive.impl;


import org.eclipse.emf.common.notify.Notification;

import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.InternalEObject;

import org.eclipse.emf.ecore.impl.ENotificationImpl;
import org.eclipse.emf.ecore.impl.EObjectImpl;

import org.example.company.company.projects.Project;

import org.example.company.company.projects.archive.ArchivePackage;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>Record</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 *   <li>{@link org.example.company.company.projects.archive.impl.RecordImpl#getProject <em>Project</em>}</li>
 * </ul>
 *
 * @generated
 */
public class RecordImpl extends EObjectImpl implements org.example.company.company.projects.archive.Record
{
  /**
   * The cached value of the '{@link #getProject() <em>Project</em>}' reference.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getProject()
   * @generated
   * @ordered
   */
  protected Project project;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  protected RecordImpl()
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
    return ArchivePackage.Literals.RECORD;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Project getProject()
  {
    if (project != null && project.eIsProxy())
    {
      InternalEObject oldProject = (InternalEObject)project;
      project = (Project)eResolveProxy(oldProject);
      if (project != oldProject)
      {
        if (eNotificationRequired())
          eNotify(new ENotificationImpl(this, Notification.RESOLVE, ArchivePackage.RECORD__PROJECT, oldProject, project));
      }
    }
    return project;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public Project basicGetProject()
  {
    return project;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setProject(Project newProject)
  {
    Project oldProject = project;
    project = newProject;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, ArchivePackage.RECORD__PROJECT, oldProject, project));
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
      case ArchivePackage.RECORD__PROJECT:
        if (resolve) return getProject();
        return basicGetProject();
    }
    return super.eGet(featureID, resolve, coreType);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void eSet(int featureID, Object newValue)
  {
    switch (featureID)
    {
      case ArchivePackage.RECORD__PROJECT:
        setProject((Project)newValue);
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
      case ArchivePackage.RECORD__PROJECT:
        setProject((Project)null);
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
      case ArchivePackage.RECORD__PROJECT:
        return project != null;
    }
    return super.eIsSet(featureID);
  }

} //RecordImpl
