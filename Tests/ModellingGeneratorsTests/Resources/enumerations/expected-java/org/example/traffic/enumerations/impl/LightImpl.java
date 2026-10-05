/**
 */
package org.example.traffic.enumerations.impl;

import org.eclipse.emf.common.notify.Notification;

import org.eclipse.emf.ecore.EClass;

import org.eclipse.emf.ecore.impl.ENotificationImpl;
import org.eclipse.emf.ecore.impl.EObjectImpl;

import org.example.traffic.enumerations.Colour;
import org.example.traffic.enumerations.EnumerationsPackage;
import org.example.traffic.enumerations.Light;
import org.example.traffic.enumerations.Mode;

/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>Light</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 *   <li>{@link org.example.traffic.enumerations.impl.LightImpl#getColour <em>Colour</em>}</li>
 *   <li>{@link org.example.traffic.enumerations.impl.LightImpl#getMode <em>Mode</em>}</li>
 * </ul>
 *
 * @generated
 */
public class LightImpl extends EObjectImpl implements Light {
	/**
	 * The default value of the '{@link #getColour() <em>Colour</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getColour()
	 * @generated
	 * @ordered
	 */
	protected static final Colour COLOUR_EDEFAULT = Colour.RED;

	/**
	 * The cached value of the '{@link #getColour() <em>Colour</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getColour()
	 * @generated
	 * @ordered
	 */
	protected Colour colour = COLOUR_EDEFAULT;

	/**
	 * The default value of the '{@link #getMode() <em>Mode</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getMode()
	 * @generated
	 * @ordered
	 */
	protected static final Mode MODE_EDEFAULT = Mode.DEFAULT;

	/**
	 * The cached value of the '{@link #getMode() <em>Mode</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getMode()
	 * @generated
	 * @ordered
	 */
	protected Mode mode = MODE_EDEFAULT;

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected LightImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected EClass eStaticClass() {
		return EnumerationsPackage.Literals.LIGHT;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Colour getColour() {
		return colour;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void setColour(Colour newColour) {
		Colour oldColour = colour;
		colour = newColour == null ? COLOUR_EDEFAULT : newColour;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, EnumerationsPackage.LIGHT__COLOUR, oldColour, colour));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Mode getMode() {
		return mode;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void setMode(Mode newMode) {
		Mode oldMode = mode;
		mode = newMode == null ? MODE_EDEFAULT : newMode;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, EnumerationsPackage.LIGHT__MODE, oldMode, mode));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object eGet(int featureID, boolean resolve, boolean coreType) {
		switch (featureID) {
			case EnumerationsPackage.LIGHT__COLOUR:
				return getColour();
			case EnumerationsPackage.LIGHT__MODE:
				return getMode();
		}
		return super.eGet(featureID, resolve, coreType);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void eSet(int featureID, Object newValue) {
		switch (featureID) {
			case EnumerationsPackage.LIGHT__COLOUR:
				setColour((Colour)newValue);
				return;
			case EnumerationsPackage.LIGHT__MODE:
				setMode((Mode)newValue);
				return;
		}
		super.eSet(featureID, newValue);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void eUnset(int featureID) {
		switch (featureID) {
			case EnumerationsPackage.LIGHT__COLOUR:
				setColour(COLOUR_EDEFAULT);
				return;
			case EnumerationsPackage.LIGHT__MODE:
				setMode(MODE_EDEFAULT);
				return;
		}
		super.eUnset(featureID);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public boolean eIsSet(int featureID) {
		switch (featureID) {
			case EnumerationsPackage.LIGHT__COLOUR:
				return colour != COLOUR_EDEFAULT;
			case EnumerationsPackage.LIGHT__MODE:
				return mode != MODE_EDEFAULT;
		}
		return super.eIsSet(featureID);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public String toString() {
		if (eIsProxy()) return super.toString();

		StringBuilder result = new StringBuilder(super.toString());
		result.append(" (colour: ");
		result.append(colour);
		result.append(", mode: ");
		result.append(mode);
		result.append(')');
		return result.toString();
	}

} //LightImpl
