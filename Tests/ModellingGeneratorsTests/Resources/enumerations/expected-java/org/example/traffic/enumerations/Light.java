/**
 */
package org.example.traffic.enumerations;

import org.eclipse.emf.ecore.EObject;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Light</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link org.example.traffic.enumerations.Light#getColour <em>Colour</em>}</li>
 *   <li>{@link org.example.traffic.enumerations.Light#getMode <em>Mode</em>}</li>
 * </ul>
 *
 * @see org.example.traffic.enumerations.EnumerationsPackage#getLight()
 * @model
 * @generated
 */
public interface Light extends EObject {
	/**
	 * Returns the value of the '<em><b>Colour</b></em>' attribute.
	 * The literals are from the enumeration {@link org.example.traffic.enumerations.Colour}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Colour</em>' attribute.
	 * @see org.example.traffic.enumerations.Colour
	 * @see #setColour(Colour)
	 * @see org.example.traffic.enumerations.EnumerationsPackage#getLight_Colour()
	 * @model
	 * @generated
	 */
	Colour getColour();

	/**
	 * Sets the value of the '{@link org.example.traffic.enumerations.Light#getColour <em>Colour</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Colour</em>' attribute.
	 * @see org.example.traffic.enumerations.Colour
	 * @see #getColour()
	 * @generated
	 */
	void setColour(Colour value);

	/**
	 * Returns the value of the '<em><b>Mode</b></em>' attribute.
	 * The literals are from the enumeration {@link org.example.traffic.enumerations.Mode}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Mode</em>' attribute.
	 * @see org.example.traffic.enumerations.Mode
	 * @see #setMode(Mode)
	 * @see org.example.traffic.enumerations.EnumerationsPackage#getLight_Mode()
	 * @model
	 * @generated
	 */
	Mode getMode();

	/**
	 * Sets the value of the '{@link org.example.traffic.enumerations.Light#getMode <em>Mode</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Mode</em>' attribute.
	 * @see org.example.traffic.enumerations.Mode
	 * @see #getMode()
	 * @generated
	 */
	void setMode(Mode value);

} // Light
