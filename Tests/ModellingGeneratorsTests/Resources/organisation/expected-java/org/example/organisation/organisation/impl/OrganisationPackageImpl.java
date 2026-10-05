/**
 */
package org.example.organisation.organisation.impl;


import org.eclipse.emf.ecore.EAttribute;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.EReference;

import org.eclipse.emf.ecore.impl.EPackageImpl;

import org.example.organisation.organisation.Organisation;
import org.example.organisation.organisation.OrganisationFactory;
import org.example.organisation.organisation.OrganisationPackage;
import org.example.organisation.organisation.Person;
import org.example.organisation.organisation.Team;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model <b>Package</b>.
 * <!-- end-user-doc -->
 * @generated
 */
public class OrganisationPackageImpl extends EPackageImpl implements OrganisationPackage
{
  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EClass personEClass = null;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EClass teamEClass = null;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EClass organisationEClass = null;

  /**
   * Creates an instance of the model <b>Package</b>, registered with
   * {@link org.eclipse.emf.ecore.EPackage.Registry EPackage.Registry} by the package
   * package URI value.
   * <p>Note: the correct way to create the package is via the static
   * factory method {@link #init init()}, which also performs
   * initialization of the package, or returns the registered package,
   * if one already exists.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.eclipse.emf.ecore.EPackage.Registry
   * @see org.example.organisation.organisation.OrganisationPackage#eNS_URI
   * @see #init()
   * @generated
   */
  private OrganisationPackageImpl()
  {
    super(eNS_URI, OrganisationFactory.eINSTANCE);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private static boolean isInited = false;

  /**
   * Creates, registers, and initializes the <b>Package</b> for this model, and for any others upon which it depends.
   *
   * <p>This method is used to initialize {@link OrganisationPackage#eINSTANCE} when that field is accessed.
   * Clients should not invoke it directly. Instead, they should simply access that field to obtain the package.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #eNS_URI
   * @see #createPackageContents()
   * @see #initializePackageContents()
   * @generated
   */
  public static OrganisationPackage init()
  {
    if (isInited) return (OrganisationPackage)EPackage.Registry.INSTANCE.getEPackage(OrganisationPackage.eNS_URI);

    // Obtain or create and register package
    Object registeredOrganisationPackage = EPackage.Registry.INSTANCE.get(eNS_URI);
    OrganisationPackageImpl theOrganisationPackage = registeredOrganisationPackage instanceof OrganisationPackageImpl ? (OrganisationPackageImpl)registeredOrganisationPackage : new OrganisationPackageImpl();

    isInited = true;

    // Create package meta-data objects
    theOrganisationPackage.createPackageContents();

    // Initialize created meta-data
    theOrganisationPackage.initializePackageContents();

    // Mark meta-data to indicate it can't be changed
    theOrganisationPackage.freeze();

    // Update the registry and return the package
    EPackage.Registry.INSTANCE.put(OrganisationPackage.eNS_URI, theOrganisationPackage);
    return theOrganisationPackage;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EClass getPerson()
  {
    return personEClass;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EAttribute getPerson_Name()
  {
    return (EAttribute)personEClass.getEStructuralFeatures().get(0);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EAttribute getPerson_Age()
  {
    return (EAttribute)personEClass.getEStructuralFeatures().get(1);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EClass getTeam()
  {
    return teamEClass;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EAttribute getTeam_Name()
  {
    return (EAttribute)teamEClass.getEStructuralFeatures().get(0);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EReference getTeam_Members()
  {
    return (EReference)teamEClass.getEStructuralFeatures().get(1);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EReference getTeam_Leader()
  {
    return (EReference)teamEClass.getEStructuralFeatures().get(2);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EClass getOrganisation()
  {
    return organisationEClass;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EAttribute getOrganisation_Name()
  {
    return (EAttribute)organisationEClass.getEStructuralFeatures().get(0);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EReference getOrganisation_Teams()
  {
    return (EReference)organisationEClass.getEStructuralFeatures().get(1);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public OrganisationFactory getOrganisationFactory()
  {
    return (OrganisationFactory)getEFactoryInstance();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private boolean isCreated = false;

  /**
   * Creates the meta-model objects for the package.  This method is
   * guarded to have no affect on any invocation but its first.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public void createPackageContents()
  {
    if (isCreated) return;
    isCreated = true;

    // Create classes and their features
    personEClass = createEClass(PERSON);
    createEAttribute(personEClass, PERSON__NAME);
    createEAttribute(personEClass, PERSON__AGE);

    teamEClass = createEClass(TEAM);
    createEAttribute(teamEClass, TEAM__NAME);
    createEReference(teamEClass, TEAM__MEMBERS);
    createEReference(teamEClass, TEAM__LEADER);

    organisationEClass = createEClass(ORGANISATION);
    createEAttribute(organisationEClass, ORGANISATION__NAME);
    createEReference(organisationEClass, ORGANISATION__TEAMS);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private boolean isInitialized = false;

  /**
   * Complete the initialization of the package and its meta-model.  This
   * method is guarded to have no affect on any invocation but its first.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public void initializePackageContents()
  {
    if (isInitialized) return;
    isInitialized = true;

    // Initialize package
    setName(eNAME);
    setNsPrefix(eNS_PREFIX);
    setNsURI(eNS_URI);

    // Create type parameters

    // Set bounds for type parameters

    // Add supertypes to classes

    // Initialize classes and features; add operations and parameters
    initEClass(personEClass, Person.class, "Person", !IS_ABSTRACT, !IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);
    initEAttribute(getPerson_Name(), ecorePackage.getEString(), "name", null, 0, 1, Person.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEAttribute(getPerson_Age(), ecorePackage.getEInt(), "age", null, 0, 1, Person.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);

    initEClass(teamEClass, Team.class, "Team", !IS_ABSTRACT, !IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);
    initEAttribute(getTeam_Name(), ecorePackage.getEString(), "name", null, 0, 1, Team.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEReference(getTeam_Members(), this.getPerson(), null, "members", null, 0, -1, Team.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, IS_COMPOSITE, !IS_RESOLVE_PROXIES, !IS_UNSETTABLE, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEReference(getTeam_Leader(), this.getPerson(), null, "leader", null, 1, 1, Team.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_COMPOSITE, IS_RESOLVE_PROXIES, !IS_UNSETTABLE, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);

    initEClass(organisationEClass, Organisation.class, "Organisation", !IS_ABSTRACT, !IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);
    initEAttribute(getOrganisation_Name(), ecorePackage.getEString(), "name", null, 0, 1, Organisation.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEReference(getOrganisation_Teams(), this.getTeam(), null, "teams", null, 0, -1, Organisation.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, IS_COMPOSITE, !IS_RESOLVE_PROXIES, !IS_UNSETTABLE, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);

    // Create resource
    createResource(eNS_URI);
  }

} //OrganisationPackageImpl
