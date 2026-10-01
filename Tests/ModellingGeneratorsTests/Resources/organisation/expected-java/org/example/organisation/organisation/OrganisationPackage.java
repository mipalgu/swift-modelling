/**
 */
package org.example.organisation.organisation;


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
 *   <li>each operation of each class,</li>
 *   <li>each enum,</li>
 *   <li>and each data type</li>
 * </ul>
 * <!-- end-user-doc -->
 * @see org.example.organisation.organisation.OrganisationFactory
 * @model kind="package"
 * @generated
 */
public interface OrganisationPackage extends EPackage
{
  /**
   * The package name.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNAME = "organisation";

  /**
   * The package namespace URI.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNS_URI = "http://swift-modelling.org/test/organisation";

  /**
   * The package namespace name.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNS_PREFIX = "org";

  /**
   * The singleton instance of the package.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  OrganisationPackage eINSTANCE = org.example.organisation.organisation.impl.OrganisationPackageImpl.init();

  /**
   * The meta object id for the '{@link org.example.organisation.organisation.impl.PersonImpl <em>Person</em>}' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.example.organisation.organisation.impl.PersonImpl
   * @see org.example.organisation.organisation.impl.OrganisationPackageImpl#getPerson()
   * @generated
   */
  int PERSON = 0;

  /**
   * The feature id for the '<em><b>Name</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int PERSON__NAME = 0;

  /**
   * The feature id for the '<em><b>Age</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int PERSON__AGE = 1;

  /**
   * The number of structural features of the '<em>Person</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int PERSON_FEATURE_COUNT = 2;

  /**
   * The number of operations of the '<em>Person</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int PERSON_OPERATION_COUNT = 0;

  /**
   * The meta object id for the '{@link org.example.organisation.organisation.impl.TeamImpl <em>Team</em>}' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.example.organisation.organisation.impl.TeamImpl
   * @see org.example.organisation.organisation.impl.OrganisationPackageImpl#getTeam()
   * @generated
   */
  int TEAM = 1;

  /**
   * The feature id for the '<em><b>Name</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int TEAM__NAME = 0;

  /**
   * The feature id for the '<em><b>Members</b></em>' containment reference list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int TEAM__MEMBERS = 1;

  /**
   * The feature id for the '<em><b>Leader</b></em>' reference.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int TEAM__LEADER = 2;

  /**
   * The number of structural features of the '<em>Team</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int TEAM_FEATURE_COUNT = 3;

  /**
   * The number of operations of the '<em>Team</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int TEAM_OPERATION_COUNT = 0;

  /**
   * The meta object id for the '{@link org.example.organisation.organisation.impl.OrganisationImpl <em>Organisation</em>}' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.example.organisation.organisation.impl.OrganisationImpl
   * @see org.example.organisation.organisation.impl.OrganisationPackageImpl#getOrganisation()
   * @generated
   */
  int ORGANISATION = 2;

  /**
   * The feature id for the '<em><b>Name</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int ORGANISATION__NAME = 0;

  /**
   * The feature id for the '<em><b>Teams</b></em>' containment reference list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int ORGANISATION__TEAMS = 1;

  /**
   * The number of structural features of the '<em>Organisation</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int ORGANISATION_FEATURE_COUNT = 2;

  /**
   * The number of operations of the '<em>Organisation</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int ORGANISATION_OPERATION_COUNT = 0;

  /**
   * Returns the meta object for class '{@link org.example.organisation.organisation.Person <em>Person</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for class '<em>Person</em>'.
   * @see org.example.organisation.organisation.Person
   * @generated
   */
  EClass getPerson();

  /**
   * Returns the meta object for the attribute '{@link org.example.organisation.organisation.Person#getName <em>Name</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute '<em>Name</em>'.
   * @see org.example.organisation.organisation.Person#getName()
   * @see #getPerson()
   * @generated
   */
  EAttribute getPerson_Name();

  /**
   * Returns the meta object for the attribute '{@link org.example.organisation.organisation.Person#getAge <em>Age</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute '<em>Age</em>'.
   * @see org.example.organisation.organisation.Person#getAge()
   * @see #getPerson()
   * @generated
   */
  EAttribute getPerson_Age();

  /**
   * Returns the meta object for class '{@link org.example.organisation.organisation.Team <em>Team</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for class '<em>Team</em>'.
   * @see org.example.organisation.organisation.Team
   * @generated
   */
  EClass getTeam();

  /**
   * Returns the meta object for the attribute '{@link org.example.organisation.organisation.Team#getName <em>Name</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute '<em>Name</em>'.
   * @see org.example.organisation.organisation.Team#getName()
   * @see #getTeam()
   * @generated
   */
  EAttribute getTeam_Name();

  /**
   * Returns the meta object for the containment reference list '{@link org.example.organisation.organisation.Team#getMembers <em>Members</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the containment reference list '<em>Members</em>'.
   * @see org.example.organisation.organisation.Team#getMembers()
   * @see #getTeam()
   * @generated
   */
  EReference getTeam_Members();

  /**
   * Returns the meta object for the reference '{@link org.example.organisation.organisation.Team#getLeader <em>Leader</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the reference '<em>Leader</em>'.
   * @see org.example.organisation.organisation.Team#getLeader()
   * @see #getTeam()
   * @generated
   */
  EReference getTeam_Leader();

  /**
   * Returns the meta object for class '{@link org.example.organisation.organisation.Organisation <em>Organisation</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for class '<em>Organisation</em>'.
   * @see org.example.organisation.organisation.Organisation
   * @generated
   */
  EClass getOrganisation();

  /**
   * Returns the meta object for the attribute '{@link org.example.organisation.organisation.Organisation#getName <em>Name</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute '<em>Name</em>'.
   * @see org.example.organisation.organisation.Organisation#getName()
   * @see #getOrganisation()
   * @generated
   */
  EAttribute getOrganisation_Name();

  /**
   * Returns the meta object for the containment reference list '{@link org.example.organisation.organisation.Organisation#getTeams <em>Teams</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the containment reference list '<em>Teams</em>'.
   * @see org.example.organisation.organisation.Organisation#getTeams()
   * @see #getOrganisation()
   * @generated
   */
  EReference getOrganisation_Teams();

  /**
   * Returns the factory that creates the instances of the model.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the factory that creates the instances of the model.
   * @generated
   */
  OrganisationFactory getOrganisationFactory();

  /**
   * <!-- begin-user-doc -->
   * Defines literals for the meta objects that represent
   * <ul>
   *   <li>each class,</li>
   *   <li>each feature of each class,</li>
   *   <li>each operation of each class,</li>
   *   <li>each enum,</li>
   *   <li>and each data type</li>
   * </ul>
   * <!-- end-user-doc -->
   * @generated
   */
  interface Literals
  {
    /**
     * The meta object literal for the '{@link org.example.organisation.organisation.impl.PersonImpl <em>Person</em>}' class.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see org.example.organisation.organisation.impl.PersonImpl
     * @see org.example.organisation.organisation.impl.OrganisationPackageImpl#getPerson()
     * @generated
     */
    EClass PERSON = eINSTANCE.getPerson();

    /**
     * The meta object literal for the '<em><b>Name</b></em>' attribute feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute PERSON__NAME = eINSTANCE.getPerson_Name();

    /**
     * The meta object literal for the '<em><b>Age</b></em>' attribute feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute PERSON__AGE = eINSTANCE.getPerson_Age();

    /**
     * The meta object literal for the '{@link org.example.organisation.organisation.impl.TeamImpl <em>Team</em>}' class.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see org.example.organisation.organisation.impl.TeamImpl
     * @see org.example.organisation.organisation.impl.OrganisationPackageImpl#getTeam()
     * @generated
     */
    EClass TEAM = eINSTANCE.getTeam();

    /**
     * The meta object literal for the '<em><b>Name</b></em>' attribute feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute TEAM__NAME = eINSTANCE.getTeam_Name();

    /**
     * The meta object literal for the '<em><b>Members</b></em>' containment reference list feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EReference TEAM__MEMBERS = eINSTANCE.getTeam_Members();

    /**
     * The meta object literal for the '<em><b>Leader</b></em>' reference feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EReference TEAM__LEADER = eINSTANCE.getTeam_Leader();

    /**
     * The meta object literal for the '{@link org.example.organisation.organisation.impl.OrganisationImpl <em>Organisation</em>}' class.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see org.example.organisation.organisation.impl.OrganisationImpl
     * @see org.example.organisation.organisation.impl.OrganisationPackageImpl#getOrganisation()
     * @generated
     */
    EClass ORGANISATION = eINSTANCE.getOrganisation();

    /**
     * The meta object literal for the '<em><b>Name</b></em>' attribute feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute ORGANISATION__NAME = eINSTANCE.getOrganisation_Name();

    /**
     * The meta object literal for the '<em><b>Teams</b></em>' containment reference list feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EReference ORGANISATION__TEAMS = eINSTANCE.getOrganisation_Teams();

  }

} //OrganisationPackage
