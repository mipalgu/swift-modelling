/**
 */
package maps;

import org.eclipse.emf.common.util.EMap;

import org.eclipse.emf.ecore.EObject;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Dictionary</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link maps.Dictionary#getEntries <em>Entries</em>}</li>
 * </ul>
 *
 * @see maps.MapsPackage#getDictionary()
 * @model
 * @generated
 */
public interface Dictionary extends EObject {
	/**
	 * Returns the value of the '<em><b>Entries</b></em>' map.
	 * The key is of type {@link java.lang.String},
	 * and the value is of type {@link int},
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Entries</em>' map.
	 * @see maps.MapsPackage#getDictionary_Entries()
	 * @model mapType="maps.StringToIntEntry&lt;org.eclipse.emf.ecore.EString, org.eclipse.emf.ecore.EInt&gt;"
	 * @generated
	 */
	EMap<String, Integer> getEntries();

} // Dictionary
