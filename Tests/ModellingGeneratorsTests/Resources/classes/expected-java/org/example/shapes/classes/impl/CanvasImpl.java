/**
 */
package org.example.shapes.classes.impl;


import java.util.Collection;

import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.common.notify.NotificationChain;

import org.eclipse.emf.common.util.EList;

import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.InternalEObject;

import org.eclipse.emf.ecore.impl.ENotificationImpl;
import org.eclipse.emf.ecore.impl.MinimalEObjectImpl;

import org.eclipse.emf.ecore.util.EObjectContainmentWithInverseEList;
import org.eclipse.emf.ecore.util.EObjectResolvingEList;
import org.eclipse.emf.ecore.util.InternalEList;

import org.example.shapes.classes.Canvas;
import org.example.shapes.classes.ClassesPackage;
import org.example.shapes.classes.Shape;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>Canvas</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 *   <li>{@link org.example.shapes.classes.impl.CanvasImpl#getShapes <em>Shapes</em>}</li>
 *   <li>{@link org.example.shapes.classes.impl.CanvasImpl#getBackground <em>Background</em>}</li>
 *   <li>{@link org.example.shapes.classes.impl.CanvasImpl#getFavourites <em>Favourites</em>}</li>
 *   <li>{@link org.example.shapes.classes.impl.CanvasImpl#getSelected <em>Selected</em>}</li>
 *   <li>{@link org.example.shapes.classes.impl.CanvasImpl#getPrimary <em>Primary</em>}</li>
 * </ul>
 *
 * @generated
 */
public class CanvasImpl extends MinimalEObjectImpl.Container implements Canvas
{
  /**
   * The cached value of the '{@link #getShapes() <em>Shapes</em>}' containment reference list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getShapes()
   * @generated
   * @ordered
   */
  protected EList<Shape> shapes;

  /**
   * The cached value of the '{@link #getBackground() <em>Background</em>}' containment reference.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getBackground()
   * @generated
   * @ordered
   */
  protected Shape background;

  /**
   * This is true if the Background containment reference has been set.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  protected boolean backgroundESet;

  /**
   * The cached value of the '{@link #getFavourites() <em>Favourites</em>}' reference list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getFavourites()
   * @generated
   * @ordered
   */
  protected EList<Shape> favourites;

  /**
   * The cached value of the '{@link #getSelected() <em>Selected</em>}' reference.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getSelected()
   * @generated
   * @ordered
   */
  protected Shape selected;

  /**
   * The cached value of the '{@link #getPrimary() <em>Primary</em>}' reference.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getPrimary()
   * @generated
   * @ordered
   */
  protected Shape primary;

  /**
   * This is true if the Primary reference has been set.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  protected boolean primaryESet;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  protected CanvasImpl()
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
    return ClassesPackage.Literals.CANVAS;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EList<Shape> getShapes()
  {
    if (shapes == null)
    {
      shapes = new EObjectContainmentWithInverseEList<Shape>(Shape.class, this, ClassesPackage.CANVAS__SHAPES, ClassesPackage.SHAPE__CANVAS);
    }
    return shapes;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Shape getBackground()
  {
    return background;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public NotificationChain basicSetBackground(Shape newBackground, NotificationChain msgs)
  {
    Shape oldBackground = background;
    background = newBackground;
    boolean oldBackgroundESet = backgroundESet;
    backgroundESet = true;
    if (eNotificationRequired())
    {
      ENotificationImpl notification = new ENotificationImpl(this, Notification.SET, ClassesPackage.CANVAS__BACKGROUND, oldBackground, newBackground, !oldBackgroundESet);
      if (msgs == null) msgs = notification; else msgs.add(notification);
    }
    return msgs;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setBackground(Shape newBackground)
  {
    if (newBackground != background)
    {
      NotificationChain msgs = null;
      if (background != null)
        msgs = ((InternalEObject)background).eInverseRemove(this, EOPPOSITE_FEATURE_BASE - ClassesPackage.CANVAS__BACKGROUND, null, msgs);
      if (newBackground != null)
        msgs = ((InternalEObject)newBackground).eInverseAdd(this, EOPPOSITE_FEATURE_BASE - ClassesPackage.CANVAS__BACKGROUND, null, msgs);
      msgs = basicSetBackground(newBackground, msgs);
      if (msgs != null) msgs.dispatch();
    }
    else
    {
      boolean oldBackgroundESet = backgroundESet;
      backgroundESet = true;
      if (eNotificationRequired())
        eNotify(new ENotificationImpl(this, Notification.SET, ClassesPackage.CANVAS__BACKGROUND, newBackground, newBackground, !oldBackgroundESet));
    }
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public NotificationChain basicUnsetBackground(NotificationChain msgs)
  {
    Shape oldBackground = background;
    background = null;
    boolean oldBackgroundESet = backgroundESet;
    backgroundESet = false;
    if (eNotificationRequired())
    {
      ENotificationImpl notification = new ENotificationImpl(this, Notification.UNSET, ClassesPackage.CANVAS__BACKGROUND, oldBackground, null, oldBackgroundESet);
      if (msgs == null) msgs = notification; else msgs.add(notification);
    }
    return msgs;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void unsetBackground()
  {
    if (background != null)
    {
      NotificationChain msgs = null;
      msgs = ((InternalEObject)background).eInverseRemove(this, EOPPOSITE_FEATURE_BASE - ClassesPackage.CANVAS__BACKGROUND, null, msgs);
      msgs = basicUnsetBackground(msgs);
      if (msgs != null) msgs.dispatch();
    }
    else
    {
      boolean oldBackgroundESet = backgroundESet;
      backgroundESet = false;
      if (eNotificationRequired())
        eNotify(new ENotificationImpl(this, Notification.UNSET, ClassesPackage.CANVAS__BACKGROUND, null, null, oldBackgroundESet));
    }
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public boolean isSetBackground()
  {
    return backgroundESet;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EList<Shape> getFavourites()
  {
    if (favourites == null)
    {
      favourites = new EObjectResolvingEList<Shape>(Shape.class, this, ClassesPackage.CANVAS__FAVOURITES);
    }
    return favourites;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Shape getSelected()
  {
    return selected;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setSelected(Shape newSelected)
  {
    Shape oldSelected = selected;
    selected = newSelected;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, ClassesPackage.CANVAS__SELECTED, oldSelected, selected));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Shape getPrimary()
  {
    if (primary != null && primary.eIsProxy())
    {
      InternalEObject oldPrimary = (InternalEObject)primary;
      primary = (Shape)eResolveProxy(oldPrimary);
      if (primary != oldPrimary)
      {
        if (eNotificationRequired())
          eNotify(new ENotificationImpl(this, Notification.RESOLVE, ClassesPackage.CANVAS__PRIMARY, oldPrimary, primary));
      }
    }
    return primary;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public Shape basicGetPrimary()
  {
    return primary;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setPrimary(Shape newPrimary)
  {
    Shape oldPrimary = primary;
    primary = newPrimary;
    boolean oldPrimaryESet = primaryESet;
    primaryESet = true;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, ClassesPackage.CANVAS__PRIMARY, oldPrimary, primary, !oldPrimaryESet));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void unsetPrimary()
  {
    Shape oldPrimary = primary;
    boolean oldPrimaryESet = primaryESet;
    primary = null;
    primaryESet = false;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.UNSET, ClassesPackage.CANVAS__PRIMARY, oldPrimary, null, oldPrimaryESet));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public boolean isSetPrimary()
  {
    return primaryESet;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @SuppressWarnings("unchecked")
  @Override
  public NotificationChain eInverseAdd(InternalEObject otherEnd, int featureID, NotificationChain msgs)
  {
    switch (featureID)
    {
      case ClassesPackage.CANVAS__SHAPES:
        return ((InternalEList<InternalEObject>)(InternalEList<?>)getShapes()).basicAdd(otherEnd, msgs);
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
      case ClassesPackage.CANVAS__SHAPES:
        return ((InternalEList<?>)getShapes()).basicRemove(otherEnd, msgs);
      case ClassesPackage.CANVAS__BACKGROUND:
        return basicUnsetBackground(msgs);
    }
    return super.eInverseRemove(otherEnd, featureID, msgs);
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
      case ClassesPackage.CANVAS__SHAPES:
        return getShapes();
      case ClassesPackage.CANVAS__BACKGROUND:
        return getBackground();
      case ClassesPackage.CANVAS__FAVOURITES:
        return getFavourites();
      case ClassesPackage.CANVAS__SELECTED:
        return getSelected();
      case ClassesPackage.CANVAS__PRIMARY:
        if (resolve) return getPrimary();
        return basicGetPrimary();
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
      case ClassesPackage.CANVAS__SHAPES:
        getShapes().clear();
        getShapes().addAll((Collection<? extends Shape>)newValue);
        return;
      case ClassesPackage.CANVAS__BACKGROUND:
        setBackground((Shape)newValue);
        return;
      case ClassesPackage.CANVAS__FAVOURITES:
        getFavourites().clear();
        getFavourites().addAll((Collection<? extends Shape>)newValue);
        return;
      case ClassesPackage.CANVAS__SELECTED:
        setSelected((Shape)newValue);
        return;
      case ClassesPackage.CANVAS__PRIMARY:
        setPrimary((Shape)newValue);
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
      case ClassesPackage.CANVAS__SHAPES:
        getShapes().clear();
        return;
      case ClassesPackage.CANVAS__BACKGROUND:
        unsetBackground();
        return;
      case ClassesPackage.CANVAS__FAVOURITES:
        getFavourites().clear();
        return;
      case ClassesPackage.CANVAS__SELECTED:
        setSelected((Shape)null);
        return;
      case ClassesPackage.CANVAS__PRIMARY:
        unsetPrimary();
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
      case ClassesPackage.CANVAS__SHAPES:
        return shapes != null && !shapes.isEmpty();
      case ClassesPackage.CANVAS__BACKGROUND:
        return isSetBackground();
      case ClassesPackage.CANVAS__FAVOURITES:
        return favourites != null && !favourites.isEmpty();
      case ClassesPackage.CANVAS__SELECTED:
        return selected != null;
      case ClassesPackage.CANVAS__PRIMARY:
        return isSetPrimary();
    }
    return super.eIsSet(featureID);
  }

} //CanvasImpl
