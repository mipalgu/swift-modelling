/**
 */
package org.example.company.company.projects.archive.impl;

import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.EReference;

import org.eclipse.emf.ecore.impl.EPackageImpl;

import org.example.company.company.CompanyPackage;

import org.example.company.company.impl.CompanyPackageImpl;

import org.example.company.company.people.PeoplePackage;

import org.example.company.company.people.impl.PeoplePackageImpl;

import org.example.company.company.projects.ProjPackage;

import org.example.company.company.projects.archive.ArchiveFactory;
import org.example.company.company.projects.archive.ArchivePackage;

import org.example.company.company.projects.impl.ProjPackageImpl;

/**
 * <!-- begin-user-doc -->
 * An implementation of the model <b>Package</b>.
 * <!-- end-user-doc -->
 * @generated
 */
public class ArchivePackageImpl extends EPackageImpl implements ArchivePackage {
	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	private EClass recordEClass = null;

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
	 * @see org.example.company.company.projects.archive.ArchivePackage#eNS_URI
	 * @see #init()
	 * @generated
	 */
	private ArchivePackageImpl() {
		super(eNS_URI, ArchiveFactory.eINSTANCE);
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
	 * <p>This method is used to initialize {@link ArchivePackage#eINSTANCE} when that field is accessed.
	 * Clients should not invoke it directly. Instead, they should simply access that field to obtain the package.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #eNS_URI
	 * @see #createPackageContents()
	 * @see #initializePackageContents()
	 * @generated
	 */
	public static ArchivePackage init() {
		if (isInited) return (ArchivePackage)EPackage.Registry.INSTANCE.getEPackage(ArchivePackage.eNS_URI);

		// Obtain or create and register package
		Object registeredArchivePackage = EPackage.Registry.INSTANCE.get(eNS_URI);
		ArchivePackageImpl theArchivePackage = registeredArchivePackage instanceof ArchivePackageImpl ? (ArchivePackageImpl)registeredArchivePackage : new ArchivePackageImpl();

		isInited = true;

		// Obtain or create and register interdependencies
		Object registeredPackage = EPackage.Registry.INSTANCE.getEPackage(CompanyPackage.eNS_URI);
		CompanyPackageImpl theCompanyPackage = (CompanyPackageImpl)(registeredPackage instanceof CompanyPackageImpl ? registeredPackage : CompanyPackage.eINSTANCE);
		registeredPackage = EPackage.Registry.INSTANCE.getEPackage(PeoplePackage.eNS_URI);
		PeoplePackageImpl thePeoplePackage = (PeoplePackageImpl)(registeredPackage instanceof PeoplePackageImpl ? registeredPackage : PeoplePackage.eINSTANCE);
		registeredPackage = EPackage.Registry.INSTANCE.getEPackage(ProjPackage.eNS_URI);
		ProjPackageImpl theProjPackage = (ProjPackageImpl)(registeredPackage instanceof ProjPackageImpl ? registeredPackage : ProjPackage.eINSTANCE);

		// Create package meta-data objects
		theArchivePackage.createPackageContents();
		theCompanyPackage.createPackageContents();
		thePeoplePackage.createPackageContents();
		theProjPackage.createPackageContents();

		// Initialize created meta-data
		theArchivePackage.initializePackageContents();
		theCompanyPackage.initializePackageContents();
		thePeoplePackage.initializePackageContents();
		theProjPackage.initializePackageContents();

		// Mark meta-data to indicate it can't be changed
		theArchivePackage.freeze();

		// Update the registry and return the package
		EPackage.Registry.INSTANCE.put(ArchivePackage.eNS_URI, theArchivePackage);
		return theArchivePackage;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public EClass getRecord() {
		return recordEClass;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public EReference getRecord_Project() {
		return (EReference)recordEClass.getEStructuralFeatures().get(0);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public ArchiveFactory getArchiveFactory() {
		return (ArchiveFactory)getEFactoryInstance();
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
	public void createPackageContents() {
		if (isCreated) return;
		isCreated = true;

		// Create classes and their features
		recordEClass = createEClass(RECORD);
		createEReference(recordEClass, RECORD__PROJECT);
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
	public void initializePackageContents() {
		if (isInitialized) return;
		isInitialized = true;

		// Initialize package
		setName(eNAME);
		setNsPrefix(eNS_PREFIX);
		setNsURI(eNS_URI);

		// Obtain other dependent packages
		ProjPackage theProjPackage = (ProjPackage)EPackage.Registry.INSTANCE.getEPackage(ProjPackage.eNS_URI);

		// Create type parameters

		// Set bounds for type parameters

		// Add supertypes to classes

		// Initialize classes and features; add operations and parameters
		initEClass(recordEClass, org.example.company.company.projects.archive.Record.class, "Record", !IS_ABSTRACT, !IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);
		initEReference(getRecord_Project(), theProjPackage.getProject(), null, "project", null, 0, 1, org.example.company.company.projects.archive.Record.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_COMPOSITE, IS_RESOLVE_PROXIES, !IS_UNSETTABLE, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
	}

} //ArchivePackageImpl
