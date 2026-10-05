/**
 */
package org.example.company.company.people.impl;

import org.eclipse.emf.ecore.EAttribute;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EPackage;

import org.eclipse.emf.ecore.impl.EPackageImpl;

import org.example.company.company.CompanyPackage;

import org.example.company.company.impl.CompanyPackageImpl;

import org.example.company.company.people.Employee;
import org.example.company.company.people.PeopleFactory;
import org.example.company.company.people.PeoplePackage;
import org.example.company.company.people.Person;

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
public class PeoplePackageImpl extends EPackageImpl implements PeoplePackage {
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
	private EClass employeeEClass = null;

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
	 * @see org.example.company.company.people.PeoplePackage#eNS_URI
	 * @see #init()
	 * @generated
	 */
	private PeoplePackageImpl() {
		super(eNS_URI, PeopleFactory.eINSTANCE);
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
	 * <p>This method is used to initialize {@link PeoplePackage#eINSTANCE} when that field is accessed.
	 * Clients should not invoke it directly. Instead, they should simply access that field to obtain the package.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #eNS_URI
	 * @see #createPackageContents()
	 * @see #initializePackageContents()
	 * @generated
	 */
	public static PeoplePackage init() {
		if (isInited) return (PeoplePackage)EPackage.Registry.INSTANCE.getEPackage(PeoplePackage.eNS_URI);

		// Obtain or create and register package
		Object registeredPeoplePackage = EPackage.Registry.INSTANCE.get(eNS_URI);
		PeoplePackageImpl thePeoplePackage = registeredPeoplePackage instanceof PeoplePackageImpl ? (PeoplePackageImpl)registeredPeoplePackage : new PeoplePackageImpl();

		isInited = true;

		// Obtain or create and register interdependencies
		Object registeredPackage = EPackage.Registry.INSTANCE.getEPackage(CompanyPackage.eNS_URI);
		CompanyPackageImpl theCompanyPackage = (CompanyPackageImpl)(registeredPackage instanceof CompanyPackageImpl ? registeredPackage : CompanyPackage.eINSTANCE);
		registeredPackage = EPackage.Registry.INSTANCE.getEPackage(ProjPackage.eNS_URI);
		ProjPackageImpl theProjPackage = (ProjPackageImpl)(registeredPackage instanceof ProjPackageImpl ? registeredPackage : ProjPackage.eINSTANCE);
		registeredPackage = EPackage.Registry.INSTANCE.getEPackage(ArchivePackage.eNS_URI);
		ArchivePackageImpl theArchivePackage = (ArchivePackageImpl)(registeredPackage instanceof ArchivePackageImpl ? registeredPackage : ArchivePackage.eINSTANCE);

		// Create package meta-data objects
		thePeoplePackage.createPackageContents();
		theCompanyPackage.createPackageContents();
		theProjPackage.createPackageContents();
		theArchivePackage.createPackageContents();

		// Initialize created meta-data
		thePeoplePackage.initializePackageContents();
		theCompanyPackage.initializePackageContents();
		theProjPackage.initializePackageContents();
		theArchivePackage.initializePackageContents();

		// Mark meta-data to indicate it can't be changed
		thePeoplePackage.freeze();

		// Update the registry and return the package
		EPackage.Registry.INSTANCE.put(PeoplePackage.eNS_URI, thePeoplePackage);
		return thePeoplePackage;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public EClass getPerson() {
		return personEClass;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public EAttribute getPerson_Name() {
		return (EAttribute)personEClass.getEStructuralFeatures().get(0);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public EClass getEmployee() {
		return employeeEClass;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public EAttribute getEmployee_Salary() {
		return (EAttribute)employeeEClass.getEStructuralFeatures().get(0);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public PeopleFactory getPeopleFactory() {
		return (PeopleFactory)getEFactoryInstance();
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
		personEClass = createEClass(PERSON);
		createEAttribute(personEClass, PERSON__NAME);

		employeeEClass = createEClass(EMPLOYEE);
		createEAttribute(employeeEClass, EMPLOYEE__SALARY);
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

		// Create type parameters

		// Set bounds for type parameters

		// Add supertypes to classes
		employeeEClass.getESuperTypes().add(this.getPerson());

		// Initialize classes and features; add operations and parameters
		initEClass(personEClass, Person.class, "Person", IS_ABSTRACT, !IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);
		initEAttribute(getPerson_Name(), ecorePackage.getEString(), "name", null, 0, 1, Person.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);

		initEClass(employeeEClass, Employee.class, "Employee", !IS_ABSTRACT, !IS_INTERFACE, IS_GENERATED_INSTANCE_CLASS);
		initEAttribute(getEmployee_Salary(), ecorePackage.getEDouble(), "salary", null, 0, 1, Employee.class, !IS_TRANSIENT, !IS_VOLATILE, IS_CHANGEABLE, !IS_UNSETTABLE, !IS_ID, IS_UNIQUE, !IS_DERIVED, IS_ORDERED);
	}

} //PeoplePackageImpl
