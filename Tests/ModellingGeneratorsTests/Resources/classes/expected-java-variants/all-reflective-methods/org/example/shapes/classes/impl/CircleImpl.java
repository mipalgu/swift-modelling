/**
 */
package org.example.shapes.classes.impl;

import java.util.Collection;

import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.impl.ENotificationImpl;
import org.example.shapes.classes.Canvas;
import org.example.shapes.classes.Circle;
import org.example.shapes.classes.ClassesPackage;
import org.example.shapes.classes.Colour;
import org.example.shapes.classes.Named;

/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>Circle</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 *   <li>{@link org.example.shapes.classes.impl.CircleImpl#getName <em>Name</em>}</li>
 *   <li>{@link org.example.shapes.classes.impl.CircleImpl#getRadius <em>Radius</em>}</li>
 *   <li>{@link org.example.shapes.classes.impl.CircleImpl#isFilled <em>Filled</em>}</li>
 * </ul>
 *
 * @generated
 */
public class CircleImpl extends ShapeImpl implements Circle {
	/**
	 * The default value of the '{@link #getName() <em>Name</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getName()
	 * @generated
	 * @ordered
	 */
	protected static final String NAME_EDEFAULT = null;

	/**
	 * The cached value of the '{@link #getName() <em>Name</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getName()
	 * @generated
	 * @ordered
	 */
	protected String name = NAME_EDEFAULT;

	/**
	 * The default value of the '{@link #getRadius() <em>Radius</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getRadius()
	 * @generated
	 * @ordered
	 */
	protected static final double RADIUS_EDEFAULT = 0.0;

	/**
	 * The cached value of the '{@link #getRadius() <em>Radius</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #getRadius()
	 * @generated
	 * @ordered
	 */
	protected double radius = RADIUS_EDEFAULT;

	/**
	 * The default value of the '{@link #isFilled() <em>Filled</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #isFilled()
	 * @generated
	 * @ordered
	 */
	protected static final boolean FILLED_EDEFAULT = false;

	/**
	 * The cached value of the '{@link #isFilled() <em>Filled</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @see #isFilled()
	 * @generated
	 * @ordered
	 */
	protected boolean filled = FILLED_EDEFAULT;

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	protected CircleImpl() {
		super();
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	protected EClass eStaticClass() {
		return ClassesPackage.Literals.CIRCLE;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public String getName() {
		return name;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void setName(String newName) {
		String oldName = name;
		name = newName;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, ClassesPackage.CIRCLE__NAME, oldName, name));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public double getRadius() {
		return radius;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void setRadius(double newRadius) {
		double oldRadius = radius;
		radius = newRadius;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, ClassesPackage.CIRCLE__RADIUS, oldRadius, radius));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public boolean isFilled() {
		return filled;
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void setFilled(boolean newFilled) {
		boolean oldFilled = filled;
		filled = newFilled;
		if (eNotificationRequired())
			eNotify(new ENotificationImpl(this, Notification.SET, ClassesPackage.CIRCLE__FILLED, oldFilled, filled));
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public Object eGet(int featureID, boolean resolve, boolean coreType) {
		switch (featureID) {
			case ClassesPackage.CIRCLE__LABEL:
				return getLabel();
			case ClassesPackage.CIRCLE__VISIBLE:
				return isVisible();
			case ClassesPackage.CIRCLE__WEIGHT:
				return getWeight();
			case ClassesPackage.CIRCLE__TAGS:
				return getTags();
			case ClassesPackage.CIRCLE__LEVELS:
				return getLevels();
			case ClassesPackage.CIRCLE__COLOUR:
				return getColour();
			case ClassesPackage.CIRCLE__DESCRIPTION:
				return getDescription();
			case ClassesPackage.CIRCLE__CANVAS:
				return getCanvas();
			case ClassesPackage.CIRCLE__NAME:
				return getName();
			case ClassesPackage.CIRCLE__RADIUS:
				return getRadius();
			case ClassesPackage.CIRCLE__FILLED:
				return isFilled();
			default:
				return eDynamicGet(featureID, resolve, coreType);
		}
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@SuppressWarnings("unchecked")
	@Override
	public void eSet(int featureID, Object newValue) {
		switch (featureID) {
			case ClassesPackage.CIRCLE__LABEL:
				setLabel((String)newValue);
				return;
			case ClassesPackage.CIRCLE__VISIBLE:
				setVisible((Boolean)newValue);
				return;
			case ClassesPackage.CIRCLE__WEIGHT:
				setWeight((Double)newValue);
				return;
			case ClassesPackage.CIRCLE__TAGS:
				getTags().clear();
				getTags().addAll((Collection<? extends String>)newValue);
				return;
			case ClassesPackage.CIRCLE__LEVELS:
				getLevels().clear();
				getLevels().addAll((Collection<? extends Integer>)newValue);
				return;
			case ClassesPackage.CIRCLE__COLOUR:
				setColour((Colour)newValue);
				return;
			case ClassesPackage.CIRCLE__DESCRIPTION:
				setDescription((String)newValue);
				return;
			case ClassesPackage.CIRCLE__CANVAS:
				setCanvas((Canvas)newValue);
				return;
			case ClassesPackage.CIRCLE__NAME:
				setName((String)newValue);
				return;
			case ClassesPackage.CIRCLE__RADIUS:
				setRadius((Double)newValue);
				return;
			case ClassesPackage.CIRCLE__FILLED:
				setFilled((Boolean)newValue);
				return;
			default:
				eDynamicSet(featureID, newValue);
				return;
		}
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public void eUnset(int featureID) {
		switch (featureID) {
			case ClassesPackage.CIRCLE__LABEL:
				unsetLabel();
				return;
			case ClassesPackage.CIRCLE__VISIBLE:
				setVisible(VISIBLE_EDEFAULT);
				return;
			case ClassesPackage.CIRCLE__WEIGHT:
				unsetWeight();
				return;
			case ClassesPackage.CIRCLE__TAGS:
				getTags().clear();
				return;
			case ClassesPackage.CIRCLE__LEVELS:
				unsetLevels();
				return;
			case ClassesPackage.CIRCLE__COLOUR:
				setColour(COLOUR_EDEFAULT);
				return;
			case ClassesPackage.CIRCLE__DESCRIPTION:
				setDescription(DESCRIPTION_EDEFAULT);
				return;
			case ClassesPackage.CIRCLE__CANVAS:
				setCanvas((Canvas)null);
				return;
			case ClassesPackage.CIRCLE__NAME:
				setName(NAME_EDEFAULT);
				return;
			case ClassesPackage.CIRCLE__RADIUS:
				setRadius(RADIUS_EDEFAULT);
				return;
			case ClassesPackage.CIRCLE__FILLED:
				setFilled(FILLED_EDEFAULT);
				return;
			default:
				eDynamicUnset(featureID);
				return;
		}
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public boolean eIsSet(int featureID) {
		switch (featureID) {
			case ClassesPackage.CIRCLE__LABEL:
				return isSetLabel();
			case ClassesPackage.CIRCLE__VISIBLE:
				return visible != VISIBLE_EDEFAULT;
			case ClassesPackage.CIRCLE__WEIGHT:
				return isSetWeight();
			case ClassesPackage.CIRCLE__TAGS:
				return tags != null && !tags.isEmpty();
			case ClassesPackage.CIRCLE__LEVELS:
				return isSetLevels();
			case ClassesPackage.CIRCLE__COLOUR:
				return colour != COLOUR_EDEFAULT;
			case ClassesPackage.CIRCLE__DESCRIPTION:
				return DESCRIPTION_EDEFAULT == null ? getDescription() != null : !DESCRIPTION_EDEFAULT.equals(getDescription());
			case ClassesPackage.CIRCLE__CANVAS:
				return getCanvas() != null;
			case ClassesPackage.CIRCLE__NAME:
				return NAME_EDEFAULT == null ? name != null : !NAME_EDEFAULT.equals(name);
			case ClassesPackage.CIRCLE__RADIUS:
				return radius != RADIUS_EDEFAULT;
			case ClassesPackage.CIRCLE__FILLED:
				return filled != FILLED_EDEFAULT;
			default:
				return eDynamicIsSet(featureID);
		}
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public int eBaseStructuralFeatureID(int derivedFeatureID, Class<?> baseClass) {
		if (baseClass == Named.class) {
			switch (derivedFeatureID) {
				case ClassesPackage.CIRCLE__NAME: return ClassesPackage.NAMED__NAME;
				default: return -1;
			}
		}
		return super.eBaseStructuralFeatureID(derivedFeatureID, baseClass);
	}

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @generated
	 */
	@Override
	public int eDerivedStructuralFeatureID(int baseFeatureID, Class<?> baseClass) {
		if (baseClass == Named.class) {
			switch (baseFeatureID) {
				case ClassesPackage.NAMED__NAME: return ClassesPackage.CIRCLE__NAME;
				default: return -1;
			}
		}
		return super.eDerivedStructuralFeatureID(baseFeatureID, baseClass);
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
		result.append(" (name: ");
		result.append(name);
		result.append(", radius: ");
		result.append(radius);
		result.append(", filled: ");
		result.append(filled);
		result.append(')');
		return result.toString();
	}

} //CircleImpl
