/**
 * Copyright 2026 Example Pty Ltd
 */
package org.example.library.impl;


import java.lang.reflect.InvocationTargetException;

import java.util.Collection;

import org.eclipse.emf.common.notify.NotificationChain;

import org.eclipse.emf.common.util.EList;

import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.InternalEObject;

import org.eclipse.emf.ecore.util.EObjectContainmentEList;
import org.eclipse.emf.ecore.util.EObjectContainmentWithInverseEList;
import org.eclipse.emf.ecore.util.InternalEList;

import org.example.library.Book;
import org.example.library.Library;
import org.example.library.LibraryPackage;
import org.example.library.Writer;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>Library</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 *   <li>{@link org.example.library.impl.LibraryImpl#getBooks <em>Books</em>}</li>
 *   <li>{@link org.example.library.impl.LibraryImpl#getWriters <em>Writers</em>}</li>
 * </ul>
 *
 * @generated
 */
public class LibraryImpl extends NamedImpl implements Library
{
  /**
   * The cached value of the '{@link #getBooks() <em>Books</em>}' containment reference list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getBooks()
   * @generated
   * @ordered
   */
  protected EList<Book> books;

  /**
   * The cached value of the '{@link #getWriters() <em>Writers</em>}' containment reference list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getWriters()
   * @generated
   * @ordered
   */
  protected EList<Writer> writers;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  protected LibraryImpl()
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
    return LibraryPackage.Literals.LIBRARY;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EList<Book> getBooks()
  {
    if (books == null)
    {
      books = new EObjectContainmentWithInverseEList<Book>(Book.class, this, LibraryPackage.LIBRARY__BOOKS, LibraryPackage.BOOK__LIBRARY);
    }
    return books;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EList<Writer> getWriters()
  {
    if (writers == null)
    {
      writers = new EObjectContainmentEList<Writer>(Writer.class, this, LibraryPackage.LIBRARY__WRITERS);
    }
    return writers;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public EList<Book> findBooks(String title, int maxResults)
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
  @SuppressWarnings("unchecked")
  @Override
  public NotificationChain eInverseAdd(InternalEObject otherEnd, int featureID, NotificationChain msgs)
  {
    switch (featureID)
    {
      case LibraryPackage.LIBRARY__BOOKS:
        return ((InternalEList<InternalEObject>)(InternalEList<?>)getBooks()).basicAdd(otherEnd, msgs);
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
      case LibraryPackage.LIBRARY__BOOKS:
        return ((InternalEList<?>)getBooks()).basicRemove(otherEnd, msgs);
      case LibraryPackage.LIBRARY__WRITERS:
        return ((InternalEList<?>)getWriters()).basicRemove(otherEnd, msgs);
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
      case LibraryPackage.LIBRARY__BOOKS:
        return getBooks();
      case LibraryPackage.LIBRARY__WRITERS:
        return getWriters();
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
      case LibraryPackage.LIBRARY__BOOKS:
        getBooks().clear();
        getBooks().addAll((Collection<? extends Book>)newValue);
        return;
      case LibraryPackage.LIBRARY__WRITERS:
        getWriters().clear();
        getWriters().addAll((Collection<? extends Writer>)newValue);
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
      case LibraryPackage.LIBRARY__BOOKS:
        getBooks().clear();
        return;
      case LibraryPackage.LIBRARY__WRITERS:
        getWriters().clear();
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
      case LibraryPackage.LIBRARY__BOOKS:
        return books != null && !books.isEmpty();
      case LibraryPackage.LIBRARY__WRITERS:
        return writers != null && !writers.isEmpty();
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
      case LibraryPackage.LIBRARY___FIND_BOOKS__STRING_INT:
        return findBooks((String)arguments.get(0), (Integer)arguments.get(1));
    }
    return super.eInvoke(operationID, arguments);
  }

} //LibraryImpl
