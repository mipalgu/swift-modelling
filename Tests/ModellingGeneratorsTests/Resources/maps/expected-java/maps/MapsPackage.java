/**
 */
package maps;


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
 * @see maps.MapsFactory
 * @model kind="package"
 * @generated
 */
public interface MapsPackage extends EPackage
{
  /**
   * The package name.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNAME = "maps";

  /**
   * The package namespace URI.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNS_URI = "http://swift-modelling.org/test/maps";

  /**
   * The package namespace name.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNS_PREFIX = "maps";

  /**
   * The singleton instance of the package.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  MapsPackage eINSTANCE = maps.impl.MapsPackageImpl.init();

  /**
   * The meta object id for the '{@link maps.impl.DictionaryImpl <em>Dictionary</em>}' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see maps.impl.DictionaryImpl
   * @see maps.impl.MapsPackageImpl#getDictionary()
   * @generated
   */
  int DICTIONARY = 0;

  /**
   * The feature id for the '<em><b>Entries</b></em>' map.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int DICTIONARY__ENTRIES = 0;

  /**
   * The number of structural features of the '<em>Dictionary</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int DICTIONARY_FEATURE_COUNT = 1;

  /**
   * The number of operations of the '<em>Dictionary</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int DICTIONARY_OPERATION_COUNT = 0;

  /**
   * The meta object id for the '{@link maps.impl.StringToIntEntryImpl <em>String To Int Entry</em>}' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see maps.impl.StringToIntEntryImpl
   * @see maps.impl.MapsPackageImpl#getStringToIntEntry()
   * @generated
   */
  int STRING_TO_INT_ENTRY = 1;

  /**
   * The feature id for the '<em><b>Key</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int STRING_TO_INT_ENTRY__KEY = 0;

  /**
   * The feature id for the '<em><b>Value</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int STRING_TO_INT_ENTRY__VALUE = 1;

  /**
   * The number of structural features of the '<em>String To Int Entry</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int STRING_TO_INT_ENTRY_FEATURE_COUNT = 2;

  /**
   * The number of operations of the '<em>String To Int Entry</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int STRING_TO_INT_ENTRY_OPERATION_COUNT = 0;

  /**
   * Returns the meta object for class '{@link maps.Dictionary <em>Dictionary</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for class '<em>Dictionary</em>'.
   * @see maps.Dictionary
   * @generated
   */
  EClass getDictionary();

  /**
   * Returns the meta object for the map '{@link maps.Dictionary#getEntries <em>Entries</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the map '<em>Entries</em>'.
   * @see maps.Dictionary#getEntries()
   * @see #getDictionary()
   * @generated
   */
  EReference getDictionary_Entries();

  /**
   * Returns the meta object for class '{@link java.util.Map.Entry <em>String To Int Entry</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for class '<em>String To Int Entry</em>'.
   * @see java.util.Map.Entry
 * @model instanceClass="java.util.Map$Entry"
   * @generated
   */
  EClass getStringToIntEntry();

  /**
   * Returns the meta object for the attribute '{@link java.util.Map.Entry#getKey <em>Key</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute '<em>Key</em>'.
   * @see java.util.Map.Entry#getKey()
   * @see #getStringToIntEntry()
   * @generated
   */
  EAttribute getStringToIntEntry_Key();

  /**
   * Returns the meta object for the attribute '{@link java.util.Map.Entry#getValue <em>Value</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute '<em>Value</em>'.
   * @see java.util.Map.Entry#getValue()
   * @see #getStringToIntEntry()
   * @generated
   */
  EAttribute getStringToIntEntry_Value();

  /**
   * Returns the factory that creates the instances of the model.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the factory that creates the instances of the model.
   * @generated
   */
  MapsFactory getMapsFactory();

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
     * The meta object literal for the '{@link maps.impl.DictionaryImpl <em>Dictionary</em>}' class.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see maps.impl.DictionaryImpl
     * @see maps.impl.MapsPackageImpl#getDictionary()
     * @generated
     */
    EClass DICTIONARY = eINSTANCE.getDictionary();

    /**
     * The meta object literal for the '<em><b>Entries</b></em>' map feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EReference DICTIONARY__ENTRIES = eINSTANCE.getDictionary_Entries();

    /**
     * The meta object literal for the '{@link maps.impl.StringToIntEntryImpl <em>String To Int Entry</em>}' class.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see maps.impl.StringToIntEntryImpl
     * @see maps.impl.MapsPackageImpl#getStringToIntEntry()
     * @generated
     */
    EClass STRING_TO_INT_ENTRY = eINSTANCE.getStringToIntEntry();

    /**
     * The meta object literal for the '<em><b>Key</b></em>' attribute feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute STRING_TO_INT_ENTRY__KEY = eINSTANCE.getStringToIntEntry_Key();

    /**
     * The meta object literal for the '<em><b>Value</b></em>' attribute feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute STRING_TO_INT_ENTRY__VALUE = eINSTANCE.getStringToIntEntry_Value();

  }

} //MapsPackage
