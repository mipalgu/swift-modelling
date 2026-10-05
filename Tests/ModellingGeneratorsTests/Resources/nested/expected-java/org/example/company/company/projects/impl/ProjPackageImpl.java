/**
 */
package org.example.company.company.projects.impl;


import org.eclipse.emf.ecore.EAttribute;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EEnum;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.EReference;

import org.eclipse.emf.ecore.impl.EPackageImpl;

import org.example.company.company.CompanyPackage;

import org.example.company.company.impl.CompanyPackageImpl;

import org.example.company.company.people.PeoplePackage;

import org.example.company.company.people.impl.PeoplePackageImpl;

import org.example.company.company.projects.ProjFactory;
import org.example.company.company.projects.ProjPackage;
import org.example.company.company.projects.Project;
import org.example.company.company.projects.Status;

import org.example.company.company.projects.archive.ArchivePackage;

import org.example.company.company.projects.archive.impl.ArchivePackageImpl;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model <b>Package</b>.
 * <!-- end-user-doc -->
 * @generated
 */
public class ProjPackageImpl extends EPackageImpl implements ProjPackage
{
  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EClass projectEClass = null;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  private EEnum statusEEnum = null;

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
   * @see org.example.company.company.projects.ProjPackage#eNS_URI
   * @see #init()
   * @generated
   */
  private ProjPackageImpl()
  {
    super(eNS_URI, ProjFactory.eINSTANCE);
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
   * <p>This method is used to initialize {@link ProjPackage#eINSTANCE} when that field is accessed.
   * Clients should not invoke it directly. Instead, they should simply access that field to obtain the package.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #eNS_URI
   * @see #createPackageContents()
   * @see #initializePackageContents()
   * @generated
   */
  public static ProjPackage init()
  {
    if (isInited) return (ProjPackage)EPackage.Registry.INSTANCE.getEPackage(ProjPackage.eNS_URI);

    // Obtain or create and register package
    Object registeredProjPackage = EPackage.Registry.INSTANCE.get(eNS_URI);
    ProjPackageImpl theProjPackage = registeredProjPackage instanceof ProjPackageImpl ? (ProjPackageImpl)registeredProjPackage : new ProjPackageImpl();

    isInited = true;

    // Obtain or create and register interdependencies
    Object registeredPackage = EPackage.Registry.INSTANCE.getEPackage(CompanyPackage.eNS_URI);
    CompanyPackageImpl theCompanyPackage = (CompanyPackageImpl)(registeredPackage instanceof CompanyPackageImpl ? registeredPackage : CompanyPackage.eINSTANCE);
    registeredPackage = EPackage.Registry.INSTANCE.getEPackage(PeoplePackage.eNS_URI);
    PeoplePackageImpl thePeoplePackage = (PeoplePackageImpl)(registeredPackage instanceof PeoplePackageImpl ? registeredPackage : PeoplePackage.eINSTANCE);
    registeredPackage = EPackage.Registry.INSTANCE.getEPackage(ArchivePackage.eNS_URI);
    ArchivePackageImpl theArchivePackage = (ArchivePackageImpl)(registeredPackage instanceof ArchivePackageImpl ? registeredPackage : ArchivePackage.eINSTANCE);

    // Create package meta-data objects
    theProjPackage.createPackageContents();
    theCompanyPackage.createPackageContents();
    thePeoplePackage.createPackageContents();
    theArchivePackage.createPackageContents();

    // Initialize created meta-data
    theProjPackage.initializePackageContents();
    theCompanyPackage.initializePackageContents();
    thePeoplePackage.initializePackageContents();
    theArchivePackage.initializePackageContents();

    // Mark meta-data to indicate it can't be changed
    theProjPackage.freeze();

    // Update the registry and return the package
    EPackage.Registry.INSTANCE.put(ProjPackage.eNS_URI, theProjPackage);
    return theProjPackage;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EClass getProject()
  {
    return projectEClass;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EAttribute getProject_Title()
  {
    return (EAttribute)projectEClass.getEStructuralFeatures().get(0);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EAttribute getProject_Status()
  {
    return (EAttribute)projectEClass.getEStructuralFeatures().get(1);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EReference getProject_Members()
  {
    return (EReference)projectEClass.getEStructuralFeatures().get(2);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EEnum getStatus()
  {
    return statusEEnum;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public ProjFactory getProjFactory()
  {
    return (ProjFactory)getEFactoryInstance();
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
    projectEClass = createEClass(PROJECT);
    createEAttribute(projectEClass, PROJECT__TITLE);
    createEAttribute(projectEClass, PROJECT__STATUS);
    createEReference(projectEClass, PROJECT__MEMBERS);

    // Create enums
    statusEEnum = createEEnum(STATUS);
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
    ArchivePackage theArchivePackage = (ArchivePackage)EPackage.Registry.INSTANCE.getEPackage(ArchivePackage.eNS_URI);
    PeoplePackage thePeoplePackage = (PeoplePackage)EPackage.Registry.INSTANCE.getEPackage(PeoplePackage.eNS_URI);

    // Add subpackages
    getESubpackages().add(theArchivePackage);

    // Create type parameters

    // Set bounds for type parameters

    // Add supertypes to classes

    // Initialize classes and features; add operations and parameters
    initEClass(projectEClass, Project.class, "Project", !IS_ABSTRACT, !IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);
    initEAttribute(getProject_Title(), ecorePackage.getEString(), "title", null, 0, 1, Project.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEAttribute(getProject_Status(), this.getStatus(), "status", null, 0, 1, Project.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
    initEReference(getProject_Members(), thePeoplePackage.getEmployee(), null, "members", null, 0, -1, Project.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_COMPOSITE, IS_RESOLVE_PROXIES, !IS_UNSETTABLE, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);

    // Initialize enums and add enum literals
    initEEnum(statusEEnum, Status.class, "Status");
    addEEnumLiteral(statusEEnum, Status.PROPOSED);
    addEEnumLiteral(statusEEnum, Status.ACTIVE);
    addEEnumLiteral(statusEEnum, Status.FINISHED);
  }

} //ProjPackageImpl
