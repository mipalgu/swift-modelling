/**
 */
package org.example.shapes.classes.impl;


import java.lang.reflect.InvocationTargetException;
import java.util.Collection;

import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.common.notify.NotificationChain;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.InternalEObject;
import org.eclipse.emf.ecore.impl.ENotificationImpl;
import org.eclipse.emf.ecore.impl.MinimalEObjectImpl;
import org.eclipse.emf.ecore.util.EDataTypeEList;
import org.eclipse.emf.ecore.util.EDataTypeUniqueEList;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.emf.ecore.util.InternalEList;
import org.example.shapes.classes.Canvas;
import org.example.shapes.classes.ClassesPackage;
import org.example.shapes.classes.Colour;
import org.example.shapes.classes.Shape;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>Shape</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 *   <li>{@link org.example.shapes.classes.impl.ShapeImpl#getLabel <em>Label</em>}</li>
 *   <li>{@link org.example.shapes.classes.impl.ShapeImpl#isVisible <em>Visible</em>}</li>
 *   <li>{@link org.example.shapes.classes.impl.ShapeImpl#getWeight <em>Weight</em>}</li>
 *   <li>{@link org.example.shapes.classes.impl.ShapeImpl#getTags <em>Tags</em>}</li>
 *   <li>{@link org.example.shapes.classes.impl.ShapeImpl#getLevels <em>Levels</em>}</li>
 *   <li>{@link org.example.shapes.classes.impl.ShapeImpl#getColour <em>Colour</em>}</li>
 *   <li>{@link org.example.shapes.classes.impl.ShapeImpl#getDescription <em>Description</em>}</li>
 *   <li>{@link org.example.shapes.classes.impl.ShapeImpl#getCanvas <em>Canvas</em>}</li>
 * </ul>
 *
 * @since 1.2
 * @generated
 */
public abstract class ShapeImpl extends MinimalEObjectImpl.Container implements Shape
{
  /**
   * The default value of the '{@link #getLabel() <em>Label</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getLabel()
   * @generated
   * @ordered
   */
  protected static final String LABEL_EDEFAULT = null;

  /**
   * The cached value of the '{@link #getLabel() <em>Label</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getLabel()
   * @generated
   * @ordered
   */
  protected String label = LABEL_EDEFAULT;

  /**
   * This is true if the Label attribute has been set.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  protected boolean labelESet;

  /**
   * The default value of the '{@link #isVisible() <em>Visible</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #isVisible()
   * @generated
   * @ordered
   */
  protected static final boolean VISIBLE_EDEFAULT = true;

  /**
   * The cached value of the '{@link #isVisible() <em>Visible</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #isVisible()
   * @generated
   * @ordered
   */
  protected boolean visible = VISIBLE_EDEFAULT;

  /**
   * The default value of the '{@link #getWeight() <em>Weight</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getWeight()
   * @generated
   * @ordered
   */
  protected static final double WEIGHT_EDEFAULT = 1.5;

  /**
   * The cached value of the '{@link #getWeight() <em>Weight</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getWeight()
   * @generated
   * @ordered
   */
  protected double weight = WEIGHT_EDEFAULT;

  /**
   * This is true if the Weight attribute has been set.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  protected boolean weightESet;

  /**
   * The cached value of the '{@link #getTags() <em>Tags</em>}' attribute list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getTags()
   * @generated
   * @ordered
   */
  protected EList<String> tags;

  /**
   * The cached value of the '{@link #getLevels() <em>Levels</em>}' attribute list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getLevels()
   * @generated
   * @ordered
   */
  protected EList<Integer> levels;

  /**
   * The default value of the '{@link #getColour() <em>Colour</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getColour()
   * @generated
   * @ordered
   */
  protected static final Colour COLOUR_EDEFAULT = Colour.GREEN;

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
   * The default value of the '{@link #getDescription() <em>Description</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getDescription()
   * @generated
   * @ordered
   */
  protected static final String DESCRIPTION_EDEFAULT = null;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  protected ShapeImpl()
  {
    super();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  protected EClass eStaticClass()
  {
    return ClassesPackage.Literals.SHAPE;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public String getLabel()
  {
    return label;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setLabel(String newLabel)
  {
    String oldLabel = label;
    label = newLabel;
    boolean oldLabelESet = labelESet;
    labelESet = true;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, ClassesPackage.SHAPE__LABEL, oldLabel, label, !oldLabelESet));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void unsetLabel()
  {
    String oldLabel = label;
    boolean oldLabelESet = labelESet;
    label = LABEL_EDEFAULT;
    labelESet = false;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.UNSET, ClassesPackage.SHAPE__LABEL, oldLabel, LABEL_EDEFAULT, oldLabelESet));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public boolean isSetLabel()
  {
    return labelESet;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public boolean isVisible()
  {
    return visible;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setVisible(boolean newVisible)
  {
    boolean oldVisible = visible;
    visible = newVisible;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, ClassesPackage.SHAPE__VISIBLE, oldVisible, visible));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public double getWeight()
  {
    return weight;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setWeight(double newWeight)
  {
    double oldWeight = weight;
    weight = newWeight;
    boolean oldWeightESet = weightESet;
    weightESet = true;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, ClassesPackage.SHAPE__WEIGHT, oldWeight, weight, !oldWeightESet));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void unsetWeight()
  {
    double oldWeight = weight;
    boolean oldWeightESet = weightESet;
    weight = WEIGHT_EDEFAULT;
    weightESet = false;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.UNSET, ClassesPackage.SHAPE__WEIGHT, oldWeight, WEIGHT_EDEFAULT, oldWeightESet));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public boolean isSetWeight()
  {
    return weightESet;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EList<String> getTags()
  {
    if (tags == null)
    {
      tags = new EDataTypeUniqueEList<String>(String.class, this, ClassesPackage.SHAPE__TAGS);
    }
    return tags;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EList<Integer> getLevels()
  {
    if (levels == null)
    {
      levels = new EDataTypeEList.Unsettable<Integer>(Integer.class, this, ClassesPackage.SHAPE__LEVELS);
    }
    return levels;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void unsetLevels()
  {
    if (levels != null) ((InternalEList.Unsettable<?>)levels).unset();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public boolean isSetLevels()
  {
    return levels != null && ((InternalEList.Unsettable<?>)levels).isSet();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Colour getColour()
  {
    return colour;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setColour(Colour newColour)
  {
    Colour oldColour = colour;
    colour = newColour == null ? COLOUR_EDEFAULT : newColour;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, ClassesPackage.SHAPE__COLOUR, oldColour, colour));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public String getDescription()
  {
    return getLabel() + " shape";
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setDescription(String newDescription)
  {
    // TODO: implement this method to set the 'Description' attribute
    // Ensure that you remove @generated or mark it @generated NOT
    throw new UnsupportedOperationException();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Canvas getCanvas()
  {
    if (eContainerFeatureID() != ClassesPackage.SHAPE__CANVAS) return null;
    return (Canvas)eInternalContainer();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public NotificationChain basicSetCanvas(Canvas newCanvas, NotificationChain msgs)
  {
    msgs = eBasicSetContainer((InternalEObject)newCanvas, ClassesPackage.SHAPE__CANVAS, msgs);
    return msgs;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setCanvas(Canvas newCanvas)
  {
    if (newCanvas != eInternalContainer() || (eContainerFeatureID() != ClassesPackage.SHAPE__CANVAS && newCanvas != null))
    {
      if (EcoreUtil.isAncestor(this, newCanvas))
        throw new IllegalArgumentException("Recursive containment not allowed for " + toString());
      NotificationChain msgs = null;
      if (eInternalContainer() != null)
        msgs = eBasicRemoveFromContainer(msgs);
      if (newCanvas != null)
        msgs = ((InternalEObject)newCanvas).eInverseAdd(this, ClassesPackage.CANVAS__SHAPES, Canvas.class, msgs);
      msgs = basicSetCanvas(newCanvas, msgs);
      if (msgs != null) msgs.dispatch();
    }
    else if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, ClassesPackage.SHAPE__CANVAS, newCanvas, newCanvas));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public double area()
  {
    return 0.0;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void move(int dx, int dy)
  {
    // TODO: implement this method
    // Ensure that you remove @generated or mark it @generated NOT
    throw new UnsupportedOperationException();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public NotificationChain eInverseAdd(InternalEObject otherEnd, int featureID, NotificationChain msgs)
  {
    switch (featureID)
    {
      case ClassesPackage.SHAPE__CANVAS:
        if (eInternalContainer() != null)
          msgs = eBasicRemoveFromContainer(msgs);
        return basicSetCanvas((Canvas)otherEnd, msgs);
    }
    return super.eInverseAdd(otherEnd, featureID, msgs);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public NotificationChain eInverseRemove(InternalEObject otherEnd, int featureID, NotificationChain msgs)
  {
    switch (featureID)
    {
      case ClassesPackage.SHAPE__CANVAS:
        return basicSetCanvas(null, msgs);
    }
    return super.eInverseRemove(otherEnd, featureID, msgs);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public NotificationChain eBasicRemoveFromContainerFeature(NotificationChain msgs)
  {
    switch (eContainerFeatureID())
    {
      case ClassesPackage.SHAPE__CANVAS:
        return eInternalContainer().eInverseRemove(this, ClassesPackage.CANVAS__SHAPES, Canvas.class, msgs);
    }
    return super.eBasicRemoveFromContainerFeature(msgs);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Object eGet(int featureID, boolean resolve, boolean coreType)
  {
    switch (featureID)
    {
      case ClassesPackage.SHAPE__LABEL:
        return getLabel();
      case ClassesPackage.SHAPE__VISIBLE:
        return isVisible();
      case ClassesPackage.SHAPE__WEIGHT:
        return getWeight();
      case ClassesPackage.SHAPE__TAGS:
        return getTags();
      case ClassesPackage.SHAPE__LEVELS:
        return getLevels();
      case ClassesPackage.SHAPE__COLOUR:
        return getColour();
      case ClassesPackage.SHAPE__DESCRIPTION:
        return getDescription();
      case ClassesPackage.SHAPE__CANVAS:
        return getCanvas();
    }
    return super.eGet(featureID, resolve, coreType);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @SuppressWarnings("unchecked")
  @Override
  public void eSet(int featureID, Object newValue)
  {
    switch (featureID)
    {
      case ClassesPackage.SHAPE__LABEL:
        setLabel((String)newValue);
        return;
      case ClassesPackage.SHAPE__VISIBLE:
        setVisible((Boolean)newValue);
        return;
      case ClassesPackage.SHAPE__WEIGHT:
        setWeight((Double)newValue);
        return;
      case ClassesPackage.SHAPE__TAGS:
        getTags().clear();
        getTags().addAll((Collection<? extends String>)newValue);
        return;
      case ClassesPackage.SHAPE__LEVELS:
        getLevels().clear();
        getLevels().addAll((Collection<? extends Integer>)newValue);
        return;
      case ClassesPackage.SHAPE__COLOUR:
        setColour((Colour)newValue);
        return;
      case ClassesPackage.SHAPE__DESCRIPTION:
        setDescription((String)newValue);
        return;
      case ClassesPackage.SHAPE__CANVAS:
        setCanvas((Canvas)newValue);
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
  public void eUnset(int featureID)
  {
    switch (featureID)
    {
      case ClassesPackage.SHAPE__LABEL:
        unsetLabel();
        return;
      case ClassesPackage.SHAPE__VISIBLE:
        setVisible(VISIBLE_EDEFAULT);
        return;
      case ClassesPackage.SHAPE__WEIGHT:
        unsetWeight();
        return;
      case ClassesPackage.SHAPE__TAGS:
        getTags().clear();
        return;
      case ClassesPackage.SHAPE__LEVELS:
        unsetLevels();
        return;
      case ClassesPackage.SHAPE__COLOUR:
        setColour(COLOUR_EDEFAULT);
        return;
      case ClassesPackage.SHAPE__DESCRIPTION:
        setDescription(DESCRIPTION_EDEFAULT);
        return;
      case ClassesPackage.SHAPE__CANVAS:
        setCanvas((Canvas)null);
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
  public boolean eIsSet(int featureID)
  {
    switch (featureID)
    {
      case ClassesPackage.SHAPE__LABEL:
        return isSetLabel();
      case ClassesPackage.SHAPE__VISIBLE:
        return visible != VISIBLE_EDEFAULT;
      case ClassesPackage.SHAPE__WEIGHT:
        return isSetWeight();
      case ClassesPackage.SHAPE__TAGS:
        return tags != null && !tags.isEmpty();
      case ClassesPackage.SHAPE__LEVELS:
        return isSetLevels();
      case ClassesPackage.SHAPE__COLOUR:
        return colour != COLOUR_EDEFAULT;
      case ClassesPackage.SHAPE__DESCRIPTION:
        return DESCRIPTION_EDEFAULT == null ? getDescription() != null : !DESCRIPTION_EDEFAULT.equals(getDescription());
      case ClassesPackage.SHAPE__CANVAS:
        return getCanvas() != null;
    }
    return super.eIsSet(featureID);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Object eInvoke(int operationID, EList<?> arguments) throws InvocationTargetException
  {
    switch (operationID)
    {
      case ClassesPackage.SHAPE___AREA:
        return area();
      case ClassesPackage.SHAPE___MOVE__INT_INT:
        move((Integer)arguments.get(0), (Integer)arguments.get(1));
        return null;
    }
    return super.eInvoke(operationID, arguments);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public String toString()
  {
    if (eIsProxy()) return super.toString();

    StringBuilder result = new StringBuilder(super.toString());
    result.append(" (label: ");
    if (labelESet) result.append(label); else result.append("<unset>");
    result.append(", visible: ");
    result.append(visible);
    result.append(", weight: ");
    if (weightESet) result.append(weight); else result.append("<unset>");
    result.append(", tags: ");
    result.append(tags);
    result.append(", levels: ");
    result.append(levels);
    result.append(", colour: ");
    result.append(colour);
    result.append(')');
    return result.toString();
  }

} //ShapeImpl
