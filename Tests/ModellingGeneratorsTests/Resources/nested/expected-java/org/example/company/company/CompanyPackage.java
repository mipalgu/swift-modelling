/**
 */
package org.example.company.company;


import org.eclipse.emf.ecore.EAttribute;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EPackage;
import org.eclipse.emf.ecore.EReference;


/**
 * <!-- begin-user-doc -->
 * The <b>Package</b> for the model.
 * It contains accessors for the meta objects to represent
 * <ul>
 *   <li>each class,</li>
 *   <li>each feature of each class,</li>
 *   <li>each enum,</li>
 *   <li>and each data type</li>
 * </ul>
 * <!-- end-user-doc -->
 * @see org.example.company.company.CompanyFactory
 * @model kind="package"
 * @generated
 */
public interface CompanyPackage extends EPackage
{
  /**
   * The package name.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNAME = "company";

  /**
   * The package namespace URI.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNS_URI = "http://swift-modelling.org/test/company";

  /**
   * The package namespace name.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNS_PREFIX = "company";

  /**
   * The singleton instance of the package.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  CompanyPackage eINSTANCE = org.example.company.company.impl.CompanyPackageImpl.init();

  /**
   * The meta object id for the '{@link org.example.company.company.impl.CompanyImpl <em>Company</em>}' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.example.company.company.impl.CompanyImpl
   * @see org.example.company.company.impl.CompanyPackageImpl#getCompany()
   * @generated
   */
  int COMPANY = 0;

  /**
   * The feature id for the '<em><b>Name</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int COMPANY__NAME = 0;

  /**
   * The feature id for the '<em><b>Staff</b></em>' containment reference list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int COMPANY__STAFF = 1;

  /**
   * The feature id for the '<em><b>Projects</b></em>' containment reference list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int COMPANY__PROJECTS = 2;

  /**
   * The number of structural features of the '<em>Company</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int COMPANY_FEATURE_COUNT = 3;

  /**
   * Returns the meta object for class '{@link org.example.company.company.Company <em>Company</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for class '<em>Company</em>'.
   * @see org.example.company.company.Company
   * @generated
   */
  EClass getCompany();

  /**
   * Returns the meta object for the attribute '{@link org.example.company.company.Company#getName <em>Name</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute '<em>Name</em>'.
   * @see org.example.company.company.Company#getName()
   * @see #getCompany()
   * @generated
   */
  EAttribute getCompany_Name();

  /**
   * Returns the meta object for the containment reference list '{@link org.example.company.company.Company#getStaff <em>Staff</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the containment reference list '<em>Staff</em>'.
   * @see org.example.company.company.Company#getStaff()
   * @see #getCompany()
   * @generated
   */
  EReference getCompany_Staff();

  /**
   * Returns the meta object for the containment reference list '{@link org.example.company.company.Company#getProjects <em>Projects</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the containment reference list '<em>Projects</em>'.
   * @see org.example.company.company.Company#getProjects()
   * @see #getCompany()
   * @generated
   */
  EReference getCompany_Projects();

  /**
   * Returns the factory that creates the instances of the model.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the factory that creates the instances of the model.
   * @generated
   */
  CompanyFactory getCompanyFactory();

  /**
   * <!-- begin-user-doc -->
   * Defines literals for the meta objects that represent
   * <ul>
   *   <li>each class,</li>
   *   <li>each feature of each class,</li>
   *   <li>each enum,</li>
   *   <li>and each data type</li>
   * </ul>
   * <!-- end-user-doc -->
   * @generated
   */
  interface Literals
  {
    /**
     * The meta object literal for the '{@link org.example.company.company.impl.CompanyImpl <em>Company</em>}' class.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see org.example.company.company.impl.CompanyImpl
     * @see org.example.company.company.impl.CompanyPackageImpl#getCompany()
     * @generated
     */
    EClass COMPANY = eINSTANCE.getCompany();

    /**
     * The meta object literal for the '<em><b>Name</b></em>' attribute feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute COMPANY__NAME = eINSTANCE.getCompany_Name();

    /**
     * The meta object literal for the '<em><b>Staff</b></em>' containment reference list feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EReference COMPANY__STAFF = eINSTANCE.getCompany_Staff();

    /**
     * The meta object literal for the '<em><b>Projects</b></em>' containment reference list feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EReference COMPANY__PROJECTS = eINSTANCE.getCompany_Projects();

  }

} //CompanyPackage
