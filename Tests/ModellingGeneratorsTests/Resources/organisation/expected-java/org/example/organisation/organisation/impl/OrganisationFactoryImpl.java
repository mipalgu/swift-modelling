/**
 */
package org.example.organisation.organisation.impl;


import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EPackage;

import org.eclipse.emf.ecore.impl.EFactoryImpl;

import org.eclipse.emf.ecore.plugin.EcorePlugin;

import org.example.organisation.organisation.*;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model <b>Factory</b>.
 * <!-- end-user-doc -->
 * @generated
 */
public class OrganisationFactoryImpl extends EFactoryImpl implements OrganisationFactory
{
  /**
   * Creates the default factory implementation.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public static OrganisationFactory init()
  {
    try
    {
      OrganisationFactory theOrganisationFactory = (OrganisationFactory)EPackage.Registry.INSTANCE.getEFactory(OrganisationPackage.eNS_URI);
      if (theOrganisationFactory != null)
      {
        return theOrganisationFactory;
      }
    }
    catch (Exception exception)
    {
      EcorePlugin.INSTANCE.log(exception);
    }
    return new OrganisationFactoryImpl();
  }

  /**
   * Creates an instance of the factory.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public OrganisationFactoryImpl()
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
      case OrganisationPackage.PERSON: return createPerson();
      case OrganisationPackage.TEAM: return createTeam();
      case OrganisationPackage.ORGANISATION: return createOrganisation();
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
  public Person createPerson()
  {
    PersonImpl person = new PersonImpl();
    return person;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Team createTeam()
  {
    TeamImpl team = new TeamImpl();
    return team;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Organisation createOrganisation()
  {
    OrganisationImpl organisation = new OrganisationImpl();
    return organisation;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public OrganisationPackage getOrganisationPackage()
  {
    return (OrganisationPackage)getEPackage();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @deprecated
   * @generated
   */
  @Deprecated
  public static OrganisationPackage getPackage()
  {
    return OrganisationPackage.eINSTANCE;
  }

} //OrganisationFactoryImpl
