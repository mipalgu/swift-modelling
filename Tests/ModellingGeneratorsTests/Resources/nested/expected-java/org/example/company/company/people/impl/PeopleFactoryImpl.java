/**
 */
package org.example.company.company.people.impl;


import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EPackage;

import org.eclipse.emf.ecore.impl.EFactoryImpl;

import org.eclipse.emf.ecore.plugin.EcorePlugin;

import org.example.company.company.people.*;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model <b>Factory</b>.
 * <!-- end-user-doc -->
 * @generated
 */
public class PeopleFactoryImpl extends EFactoryImpl implements PeopleFactory
{
  /**
   * Creates the default factory implementation.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public static PeopleFactory init()
  {
    try
    {
      PeopleFactory thePeopleFactory = (PeopleFactory)EPackage.Registry.INSTANCE.getEFactory(PeoplePackage.eNS_URI);
      if (thePeopleFactory != null)
      {
        return thePeopleFactory;
      }
    }
    catch (Exception exception)
    {
      EcorePlugin.INSTANCE.log(exception);
    }
    return new PeopleFactoryImpl();
  }

  /**
   * Creates an instance of the factory.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public PeopleFactoryImpl()
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
      case PeoplePackage.EMPLOYEE: return createEmployee();
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
  public Employee createEmployee()
  {
    EmployeeImpl employee = new EmployeeImpl();
    return employee;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public PeoplePackage getPeoplePackage()
  {
    return (PeoplePackage)getEPackage();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @deprecated
   * @generated
   */
  @Deprecated
  public static PeoplePackage getPackage()
  {
    return PeoplePackage.eINSTANCE;
  }

} //PeopleFactoryImpl
