/**
 * Copyright 2026 Example Pty Ltd
 */
package org.example.library.impl;


import org.eclipse.emf.common.notify.Notification;
import org.eclipse.emf.common.notify.NotificationChain;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.InternalEObject;
import org.eclipse.emf.ecore.impl.ENotificationImpl;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.example.library.Book;
import org.example.library.BookCategory;
import org.example.library.Lendable;
import org.example.library.Library;
import org.example.library.LibraryPackage;
import org.example.library.Writer;


/**
 * <!-- begin-user-doc -->
 * An implementation of the model object '<em><b>Book</b></em>'.
 * <!-- end-user-doc -->
 * <p>
 * The following features are implemented:
 * </p>
 * <ul>
 *   <li>{@link org.example.library.impl.BookImpl#getLoanDays <em>Loan Days</em>}</li>
 *   <li>{@link org.example.library.impl.BookImpl#isOnLoan <em>On Loan</em>}</li>
 *   <li>{@link org.example.library.impl.BookImpl#getPages <em>Pages</em>}</li>
 *   <li>{@link org.example.library.impl.BookImpl#getCategory <em>Category</em>}</li>
 *   <li>{@link org.example.library.impl.BookImpl#getIsbn <em>Isbn</em>}</li>
 *   <li>{@link org.example.library.impl.BookImpl#getAuthor <em>Author</em>}</li>
 *   <li>{@link org.example.library.impl.BookImpl#getLibrary <em>Library</em>}</li>
 * </ul>
 *
 * @generated
 */
public class BookImpl extends NamedImpl implements Book
{
  /**
   * The default value of the '{@link #getLoanDays() <em>Loan Days</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getLoanDays()
   * @generated
   * @ordered
   */
  protected static final int LOAN_DAYS_EDEFAULT = 14;

  /**
   * The cached value of the '{@link #getLoanDays() <em>Loan Days</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getLoanDays()
   * @generated
   * @ordered
   */
  protected int loanDays = LOAN_DAYS_EDEFAULT;

  /**
   * The default value of the '{@link #isOnLoan() <em>On Loan</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #isOnLoan()
   * @generated
   * @ordered
   */
  protected static final boolean ON_LOAN_EDEFAULT = false;

  /**
   * The cached value of the '{@link #isOnLoan() <em>On Loan</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #isOnLoan()
   * @generated
   * @ordered
   */
  protected boolean onLoan = ON_LOAN_EDEFAULT;

  /**
   * The default value of the '{@link #getPages() <em>Pages</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getPages()
   * @generated
   * @ordered
   */
  protected static final int PAGES_EDEFAULT = 100;

  /**
   * The cached value of the '{@link #getPages() <em>Pages</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getPages()
   * @generated
   * @ordered
   */
  protected int pages = PAGES_EDEFAULT;

  /**
   * The default value of the '{@link #getCategory() <em>Category</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getCategory()
   * @generated
   * @ordered
   */
  protected static final BookCategory CATEGORY_EDEFAULT = BookCategory.MYSTERY;

  /**
   * The cached value of the '{@link #getCategory() <em>Category</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getCategory()
   * @generated
   * @ordered
   */
  protected BookCategory category = CATEGORY_EDEFAULT;

  /**
   * The default value of the '{@link #getIsbn() <em>Isbn</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getIsbn()
   * @generated
   * @ordered
   */
  protected static final String ISBN_EDEFAULT = null;

  /**
   * The cached value of the '{@link #getIsbn() <em>Isbn</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getIsbn()
   * @generated
   * @ordered
   */
  protected String isbn = ISBN_EDEFAULT;

  /**
   * The cached value of the '{@link #getAuthor() <em>Author</em>}' reference.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see #getAuthor()
   * @generated
   * @ordered
   */
  protected Writer author;

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  protected BookImpl()
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
    return LibraryPackage.Literals.BOOK;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public int getLoanDays()
  {
    return loanDays;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setLoanDays(int newLoanDays)
  {
    int oldLoanDays = loanDays;
    loanDays = newLoanDays;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, LibraryPackage.BOOK__LOAN_DAYS, oldLoanDays, loanDays));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public boolean isOnLoan()
  {
    return onLoan;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setOnLoan(boolean newOnLoan)
  {
    boolean oldOnLoan = onLoan;
    onLoan = newOnLoan;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, LibraryPackage.BOOK__ON_LOAN, oldOnLoan, onLoan));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public int getPages()
  {
    return pages;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setPages(int newPages)
  {
    int oldPages = pages;
    pages = newPages;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, LibraryPackage.BOOK__PAGES, oldPages, pages));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public BookCategory getCategory()
  {
    return category;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setCategory(BookCategory newCategory)
  {
    BookCategory oldCategory = category;
    category = newCategory == null ? CATEGORY_EDEFAULT : newCategory;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, LibraryPackage.BOOK__CATEGORY, oldCategory, category));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public String getIsbn()
  {
    return isbn;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setIsbn(String newIsbn)
  {
    String oldIsbn = isbn;
    isbn = newIsbn;
    if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, LibraryPackage.BOOK__ISBN, oldIsbn, isbn));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Writer getAuthor()
  {
    if (author != null && author.eIsProxy())
    {
      InternalEObject oldAuthor = (InternalEObject)author;
      author = (Writer)eResolveProxy(oldAuthor);
      if (author != oldAuthor)
      {
        if (eNotificationRequired())
          eNotify(new ENotificationImpl(this, Notification.RESOLVE, LibraryPackage.BOOK__AUTHOR, oldAuthor, author));
      }
    }
    return author;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public Writer basicGetAuthor()
  {
    return author;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public NotificationChain basicSetAuthor(Writer newAuthor, NotificationChain msgs)
  {
    Writer oldAuthor = author;
    author = newAuthor;
    if (eNotificationRequired())
    {
      ENotificationImpl notification = new ENotificationImpl(this, Notification.SET, LibraryPackage.BOOK__AUTHOR, oldAuthor, newAuthor);
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
  public void setAuthor(Writer newAuthor)
  {
    if (newAuthor != author)
    {
      NotificationChain msgs = null;
      if (author != null)
        msgs = ((InternalEObject)author).eInverseRemove(this, LibraryPackage.WRITER__BOOKS, Writer.class, msgs);
      if (newAuthor != null)
        msgs = ((InternalEObject)newAuthor).eInverseAdd(this, LibraryPackage.WRITER__BOOKS, Writer.class, msgs);
      msgs = basicSetAuthor(newAuthor, msgs);
      if (msgs != null) msgs.dispatch();
    }
    else if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, LibraryPackage.BOOK__AUTHOR, newAuthor, newAuthor));
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public Library getLibrary()
  {
    if (eContainerFeatureID() != LibraryPackage.BOOK__LIBRARY) return null;
    return (Library)eInternalContainer();
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  public NotificationChain basicSetLibrary(Library newLibrary, NotificationChain msgs)
  {
    msgs = eBasicSetContainer((InternalEObject)newLibrary, LibraryPackage.BOOK__LIBRARY, msgs);
    return msgs;
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void setLibrary(Library newLibrary)
  {
    if (newLibrary != eInternalContainer() || (eContainerFeatureID() != LibraryPackage.BOOK__LIBRARY && newLibrary != null))
    {
      if (EcoreUtil.isAncestor(this, newLibrary))
        throw new IllegalArgumentException("Recursive containment not allowed for " + toString());
      NotificationChain msgs = null;
      if (eInternalContainer() != null)
        msgs = eBasicRemoveFromContainer(msgs);
      if (newLibrary != null)
        msgs = ((InternalEObject)newLibrary).eInverseAdd(this, LibraryPackage.LIBRARY__BOOKS, Library.class, msgs);
      msgs = basicSetLibrary(newLibrary, msgs);
      if (msgs != null) msgs.dispatch();
    }
    else if (eNotificationRequired())
      eNotify(new ENotificationImpl(this, Notification.SET, LibraryPackage.BOOK__LIBRARY, newLibrary, newLibrary));
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
      case LibraryPackage.BOOK__AUTHOR:
        if (author != null)
          msgs = ((InternalEObject)author).eInverseRemove(this, LibraryPackage.WRITER__BOOKS, Writer.class, msgs);
        return basicSetAuthor((Writer)otherEnd, msgs);
      case LibraryPackage.BOOK__LIBRARY:
        if (eInternalContainer() != null)
          msgs = eBasicRemoveFromContainer(msgs);
        return basicSetLibrary((Library)otherEnd, msgs);
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
      case LibraryPackage.BOOK__AUTHOR:
        return basicSetAuthor(null, msgs);
      case LibraryPackage.BOOK__LIBRARY:
        return basicSetLibrary(null, msgs);
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
      case LibraryPackage.BOOK__LIBRARY:
        return eInternalContainer().eInverseRemove(this, LibraryPackage.LIBRARY__BOOKS, Library.class, msgs);
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
      case LibraryPackage.BOOK__LOAN_DAYS:
        return getLoanDays();
      case LibraryPackage.BOOK__ON_LOAN:
        return isOnLoan();
      case LibraryPackage.BOOK__PAGES:
        return getPages();
      case LibraryPackage.BOOK__CATEGORY:
        return getCategory();
      case LibraryPackage.BOOK__ISBN:
        return getIsbn();
      case LibraryPackage.BOOK__AUTHOR:
        if (resolve) return getAuthor();
        return basicGetAuthor();
      case LibraryPackage.BOOK__LIBRARY:
        return getLibrary();
    }
    return super.eGet(featureID, resolve, coreType);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public void eSet(int featureID, Object newValue)
  {
    switch (featureID)
    {
      case LibraryPackage.BOOK__LOAN_DAYS:
        setLoanDays((Integer)newValue);
        return;
      case LibraryPackage.BOOK__ON_LOAN:
        setOnLoan((Boolean)newValue);
        return;
      case LibraryPackage.BOOK__PAGES:
        setPages((Integer)newValue);
        return;
      case LibraryPackage.BOOK__CATEGORY:
        setCategory((BookCategory)newValue);
        return;
      case LibraryPackage.BOOK__ISBN:
        setIsbn((String)newValue);
        return;
      case LibraryPackage.BOOK__AUTHOR:
        setAuthor((Writer)newValue);
        return;
      case LibraryPackage.BOOK__LIBRARY:
        setLibrary((Library)newValue);
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
      case LibraryPackage.BOOK__LOAN_DAYS:
        setLoanDays(LOAN_DAYS_EDEFAULT);
        return;
      case LibraryPackage.BOOK__ON_LOAN:
        setOnLoan(ON_LOAN_EDEFAULT);
        return;
      case LibraryPackage.BOOK__PAGES:
        setPages(PAGES_EDEFAULT);
        return;
      case LibraryPackage.BOOK__CATEGORY:
        setCategory(CATEGORY_EDEFAULT);
        return;
      case LibraryPackage.BOOK__ISBN:
        setIsbn(ISBN_EDEFAULT);
        return;
      case LibraryPackage.BOOK__AUTHOR:
        setAuthor((Writer)null);
        return;
      case LibraryPackage.BOOK__LIBRARY:
        setLibrary((Library)null);
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
      case LibraryPackage.BOOK__LOAN_DAYS:
        return loanDays != LOAN_DAYS_EDEFAULT;
      case LibraryPackage.BOOK__ON_LOAN:
        return onLoan != ON_LOAN_EDEFAULT;
      case LibraryPackage.BOOK__PAGES:
        return pages != PAGES_EDEFAULT;
      case LibraryPackage.BOOK__CATEGORY:
        return category != CATEGORY_EDEFAULT;
      case LibraryPackage.BOOK__ISBN:
        return ISBN_EDEFAULT == null ? isbn != null : !ISBN_EDEFAULT.equals(isbn);
      case LibraryPackage.BOOK__AUTHOR:
        return author != null;
      case LibraryPackage.BOOK__LIBRARY:
        return getLibrary() != null;
    }
    return super.eIsSet(featureID);
  }

  /**
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  @Override
  public int eBaseStructuralFeatureID(int derivedFeatureID, Class<?> baseClass)
  {
    if (baseClass == Lendable.class)
    {
      switch (derivedFeatureID)
      {
        case LibraryPackage.BOOK__LOAN_DAYS: return LibraryPackage.LENDABLE__LOAN_DAYS;
        case LibraryPackage.BOOK__ON_LOAN: return LibraryPackage.LENDABLE__ON_LOAN;
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
  public int eDerivedStructuralFeatureID(int baseFeatureID, Class<?> baseClass)
  {
    if (baseClass == Lendable.class)
    {
      switch (baseFeatureID)
      {
        case LibraryPackage.LENDABLE__LOAN_DAYS: return LibraryPackage.BOOK__LOAN_DAYS;
        case LibraryPackage.LENDABLE__ON_LOAN: return LibraryPackage.BOOK__ON_LOAN;
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
  public String toString()
  {
    if (eIsProxy()) return super.toString();

    StringBuilder result = new StringBuilder(super.toString());
    result.append(" (loanDays: ");
    result.append(loanDays);
    result.append(", onLoan: ");
    result.append(onLoan);
    result.append(", pages: ");
    result.append(pages);
    result.append(", category: ");
    result.append(category);
    result.append(", isbn: ");
    result.append(isbn);
    result.append(')');
    return result.toString();
  }

} //BookImpl
