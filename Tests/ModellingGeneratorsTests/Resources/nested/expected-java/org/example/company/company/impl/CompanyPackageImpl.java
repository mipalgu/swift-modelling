/**
 */
package org.example.company.company.impl;


import org.eclipse.emf.ecore.EAttribute;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.EReference;

import org.eclipse.emf.ecore.impl.EPackageImpl;

import org.example.company.company.Company;
import org.example.company.company.CompanyFactory;
import org.example.company.company.CompanyPackage;

import org.example.company.company.people.PeoplePackage;

import org.example.company.company.people.impl.PeoplePackageImpl;

import org.example.company.company.projects.ProjPackage;

import org.example.company.company.projects.archive.ArchivePackage;

import org.example.company.company.projects.archive.impl.ArchivePackageImpl;

import org.example.company.company.projects.impl.ProjPackageImpl;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model <b>Package</b>.
 * <!-- end-user-doc -->
 * @generated
 */
public class CompanyPackageImpl extends EPackageImpl implements CompanyPackage
{
  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EClass companyEClass = null;

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
   * @see org.example.company.company.CompanyPackage#eNS_URI
   * @see #init()
   * @generated
   */
  private CompanyPackageImpl()
  {
    super(eNS_URI, CompanyFactory.eINSTANCE);
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
   * <p>This method is used to initialize {@link CompanyPackage#eINSTANCE} when that field is accessed.
   * Clients should not invoke it directly. Instead, they should simply access that field to obtain the package.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #eNS_URI
   * @see #createPackageContents()
   * @see #initializePackageContents()
   * @generated
   */
  public static CompanyPackage init()
  {
    if (isInited) return (CompanyPackage)EPackage.Registry.INSTANCE.getEPackage(CompanyPackage.eNS_URI);

    // Obtain or create and register package
    Object registeredCompanyPackage = EPackage.Registry.INSTANCE.get(eNS_URI);
    CompanyPackageImpl theCompanyPackage = registeredCompanyPackage instanceof CompanyPackageImpl ? (CompanyPackageImpl)registeredCompanyPackage : new CompanyPackageImpl();

    isInited = true;

    // Obtain or create and register interdependencies
    Object registeredPackage = EPackage.Registry.INSTANCE.getEPackage(PeoplePackage.eNS_URI);
    PeoplePackageImpl thePeoplePackage = (PeoplePackageImpl)(registeredPackage instanceof PeoplePackageImpl ? registeredPackage : PeoplePackage.eINSTANCE);
    registeredPackage = EPackage.Registry.INSTANCE.getEPackage(ProjPackage.eNS_URI);
    ProjPackageImpl theProjPackage = (ProjPackageImpl)(registeredPackage instanceof ProjPackageImpl ? registeredPackage : ProjPackage.eINSTANCE);
    registeredPackage = EPackage.Registry.INSTANCE.getEPackage(ArchivePackage.eNS_URI);
    ArchivePackageImpl theArchivePackage = (ArchivePackageImpl)(registeredPackage instanceof ArchivePackageImpl ? registeredPackage : ArchivePackage.eINSTANCE);

    // Create package meta-data objects
    theCompanyPackage.createPackageContents();
    thePeoplePackage.createPackageContents();
    theProjPackage.createPackageContents();
    theArchivePackage.createPackageContents();

    // Initialize created meta-data
    theCompanyPackage.initializePackageContents();
    thePeoplePackage.initializePackageContents();
    theProjPackage.initializePackageContents();
    theArchivePackage.initializePackageContents();

    // Mark meta-data to indicate it can't be changed
    theCompanyPackage.freeze();

    // Update the registry and return the package
    EPackage.Registry.INSTANCE.put(CompanyPackage.eNS_URI, theCompanyPackage);
    return theCompanyPackage;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EClass getCompany()
  {
    return companyEClass;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EAttribute getCompany_Name()
  {
    return (EAttribute)companyEClass.getEStructuralFeatures().get(0);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EReference getCompany_Staff()
  {
    return (EReference)companyEClass.getEStructuralFeatures().get(1);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EReference getCompany_Projects()
  {
    return (EReference)companyEClass.getEStructuralFeatures().get(2);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public CompanyFactory getCompanyFactory()
  {
    return (CompanyFactory)getEFactoryInstance();
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
    companyEClass = createEClass(COMPANY);
    createEAttribute(companyEClass, COMPANY__NAME);
    createEReference(companyEClass, COMPANY__STAFF);
    createEReference(companyEClass, COMPANY__PROJECTS);
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

    // Obtain other dependent packages
    PeoplePackage thePeoplePackage = (PeoplePackage)EPackage.Registry.INSTANCE.getEPackage(PeoplePackage.eNS_URI);
    ProjPackage theProjPackage = (ProjPackage)EPackage.Registry.INSTANCE.getEPackage(ProjPackage.eNS_URI);

    // Add subpackages
    getESubpackages().add(thePeoplePackage);
    getESubpackages().add(theProjPackage);

    // Create type parameters

    // Set bounds for type parameters

    // Add supertypes to classes

    // Initialize classes, features, and operations; add parameters
    initEClass(companyEClass, Company.class, "Company", !IS_ABSTRACT, !IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);
    initEAttribute(getCompany_Name(), ecorePackage.getEString(), "name", null, 0, 1, Company.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEReference(getCompany_Staff(), thePeoplePackage.getEmployee(), null, "staff", null, 0, -1, Company.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, IS_COMPOSITE, !IS_RESOLVE_PROXIES, !IS_UNSETTABLE, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEReference(getCompany_Projects(), theProjPackage.getProject(), null, "projects", null, 0, -1, Company.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, IS_COMPOSITE, !IS_RESOLVE_PROXIES, !IS_UNSETTABLE, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);

    // Create resource
    createResource(eNS_URI);
  }

} //CompanyPackageImpl
