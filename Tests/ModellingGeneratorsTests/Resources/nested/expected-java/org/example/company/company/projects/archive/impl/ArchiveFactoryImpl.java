/**
 */
package org.example.company.company.projects.archive.impl;


import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EPackage;

import org.eclipse.emf.ecore.impl.EFactoryImpl;

import org.eclipse.emf.ecore.plugin.EcorePlugin;

import org.example.company.company.projects.archive.ArchiveFactory;
import org.example.company.company.projects.archive.ArchivePackage;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model <b>Factory</b>.
 * <!-- end-user-doc -->
 * @generated
 */
public class ArchiveFactoryImpl extends EFactoryImpl implements ArchiveFactory
{
  /**
   * Creates the default factory implementation.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public static ArchiveFactory init()
  {
    try
    {
      ArchiveFactory theArchiveFactory = (ArchiveFactory)EPackage.Registry.INSTANCE.getEFactory(ArchivePackage.eNS_URI);
      if (theArchiveFactory != null)
      {
        return theArchiveFactory;
      }
    }
    catch (Exception exception)
    {
      EcorePlugin.INSTANCE.log(exception);
    }
    return new ArchiveFactoryImpl();
  }

  /**
   * Creates an instance of the factory.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public ArchiveFactoryImpl()
  {
    super();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EObject create(EClass eClass)
  {
    switch (eClass.getClassifierID())
    {
      case ArchivePackage.RECORD: return createRecord();
      default:
        throw new IllegalArgumentException("The class '" + eClass.getName() + "' is not a valid classifier");
    }
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public org.example.company.company.projects.archive.Record createRecord()
  {
    RecordImpl record = new RecordImpl();
    return record;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public ArchivePackage getArchivePackage()
  {
    return (ArchivePackage)getEPackage();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @deprecated
   * @generated
   */
  @Deprecated
  public static ArchivePackage getPackage()
  {
    return ArchivePackage.eINSTANCE;
  }

} //ArchiveFactoryImpl
