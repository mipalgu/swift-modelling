/**
 * Copyright 2026 Example Pty Ltd
 */
package org.example.library;

import org.eclipse.emf.ecore.EAttribute;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EDataType;
import org.eclipse.emf.ecore.EEnum;
import org.eclipse.emf.ecore.EOperation;
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
 * @see org.example.library.LibraryFactory
 * @model kind="package"
 * @generated
 */
public interface LibraryPackage extends EPackage
{
  /**
   * The package name.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNAME = "library";

  /**
   * The package namespace URI.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNS_URI = "http://swift-modelling.org/test/library/1.0";

  /**
   * The package namespace name.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  String eNS_PREFIX = "lib";

  /**
   * The singleton instance of the package.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   */
  LibraryPackage eINSTANCE = org.example.library.impl.LibraryPackageImpl.init();

  /**
   * The meta object id for the '{@link org.example.library.impl.NamedImpl <em>Named</em>}' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.example.library.impl.NamedImpl
   * @see org.example.library.impl.LibraryPackageImpl#getNamed()
   * @generated
   */
  int NAMED = 0;

  /**
   * The feature id for the '<em><b>Name</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int NAMED__NAME = 0;

  /**
   * The number of structural features of the '<em>Named</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int NAMED_FEATURE_COUNT = 1;

  /**
   * The number of operations of the '<em>Named</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int NAMED_OPERATION_COUNT = 0;

  /**
   * The meta object id for the '{@link org.example.library.Lendable <em>Lendable</em>}' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.example.library.Lendable
   * @see org.example.library.impl.LibraryPackageImpl#getLendable()
   * @generated
   */
  int LENDABLE = 1;

  /**
   * The feature id for the '<em><b>Loan Days</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int LENDABLE__LOAN_DAYS = 0;

  /**
   * The feature id for the '<em><b>On Loan</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int LENDABLE__ON_LOAN = 1;

  /**
   * The number of structural features of the '<em>Lendable</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int LENDABLE_FEATURE_COUNT = 2;

  /**
   * The number of operations of the '<em>Lendable</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int LENDABLE_OPERATION_COUNT = 0;

  /**
   * The meta object id for the '{@link org.example.library.impl.BookImpl <em>Book</em>}' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.example.library.impl.BookImpl
   * @see org.example.library.impl.LibraryPackageImpl#getBook()
   * @generated
   */
  int BOOK = 2;

  /**
   * The feature id for the '<em><b>Name</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int BOOK__NAME = NAMED__NAME;

  /**
   * The feature id for the '<em><b>Loan Days</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int BOOK__LOAN_DAYS = NAMED_FEATURE_COUNT + 0;

  /**
   * The feature id for the '<em><b>On Loan</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int BOOK__ON_LOAN = NAMED_FEATURE_COUNT + 1;

  /**
   * The feature id for the '<em><b>Pages</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int BOOK__PAGES = NAMED_FEATURE_COUNT + 2;

  /**
   * The feature id for the '<em><b>Category</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int BOOK__CATEGORY = NAMED_FEATURE_COUNT + 3;

  /**
   * The feature id for the '<em><b>Isbn</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int BOOK__ISBN = NAMED_FEATURE_COUNT + 4;

  /**
   * The feature id for the '<em><b>Author</b></em>' reference.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int BOOK__AUTHOR = NAMED_FEATURE_COUNT + 5;

  /**
   * The feature id for the '<em><b>Library</b></em>' container reference.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int BOOK__LIBRARY = NAMED_FEATURE_COUNT + 6;

  /**
   * The number of structural features of the '<em>Book</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int BOOK_FEATURE_COUNT = NAMED_FEATURE_COUNT + 7;

  /**
   * The number of operations of the '<em>Book</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int BOOK_OPERATION_COUNT = NAMED_OPERATION_COUNT + 0;

  /**
   * The meta object id for the '{@link org.example.library.impl.WriterImpl <em>Writer</em>}' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.example.library.impl.WriterImpl
   * @see org.example.library.impl.LibraryPackageImpl#getWriter()
   * @generated
   */
  int WRITER = 3;

  /**
   * The feature id for the '<em><b>Name</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int WRITER__NAME = NAMED__NAME;

  /**
   * The feature id for the '<em><b>Aliases</b></em>' attribute list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int WRITER__ALIASES = NAMED_FEATURE_COUNT + 0;

  /**
   * The feature id for the '<em><b>Books</b></em>' reference list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int WRITER__BOOKS = NAMED_FEATURE_COUNT + 1;

  /**
   * The number of structural features of the '<em>Writer</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int WRITER_FEATURE_COUNT = NAMED_FEATURE_COUNT + 2;

  /**
   * The number of operations of the '<em>Writer</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int WRITER_OPERATION_COUNT = NAMED_OPERATION_COUNT + 0;

  /**
   * The meta object id for the '{@link org.example.library.impl.LibraryImpl <em>Library</em>}' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.example.library.impl.LibraryImpl
   * @see org.example.library.impl.LibraryPackageImpl#getLibrary()
   * @generated
   */
  int LIBRARY = 4;

  /**
   * The feature id for the '<em><b>Name</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int LIBRARY__NAME = NAMED__NAME;

  /**
   * The feature id for the '<em><b>Books</b></em>' containment reference list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int LIBRARY__BOOKS = NAMED_FEATURE_COUNT + 0;

  /**
   * The feature id for the '<em><b>Writers</b></em>' containment reference list.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int LIBRARY__WRITERS = NAMED_FEATURE_COUNT + 1;

  /**
   * The number of structural features of the '<em>Library</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int LIBRARY_FEATURE_COUNT = NAMED_FEATURE_COUNT + 2;

  /**
   * The operation id for the '<em>Find Books</em>' operation.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int LIBRARY___FIND_BOOKS__STRING_INT = NAMED_OPERATION_COUNT + 0;

  /**
   * The number of operations of the '<em>Library</em>' class.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @generated
   * @ordered
   */
  int LIBRARY_OPERATION_COUNT = NAMED_OPERATION_COUNT + 1;

  /**
   * The meta object id for the '{@link org.example.library.BookCategory <em>Book Category</em>}' enum.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see org.example.library.BookCategory
   * @see org.example.library.impl.LibraryPackageImpl#getBookCategory()
   * @generated
   */
  int BOOK_CATEGORY = 5;

  /**
   * The meta object id for the '<em>ISBN</em>' data type.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @see java.lang.String
   * @see org.example.library.impl.LibraryPackageImpl#getISBN()
   * @generated
   */
  int ISBN = 6;


  /**
   * Returns the meta object for class '{@link org.example.library.Named <em>Named</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for class '<em>Named</em>'.
   * @see org.example.library.Named
   * @generated
   */
  EClass getNamed();

  /**
   * Returns the meta object for the attribute '{@link org.example.library.Named#getName <em>Name</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute '<em>Name</em>'.
   * @see org.example.library.Named#getName()
   * @see #getNamed()
   * @generated
   */
  EAttribute getNamed_Name();

  /**
   * Returns the meta object for class '{@link org.example.library.Lendable <em>Lendable</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for class '<em>Lendable</em>'.
   * @see org.example.library.Lendable
   * @generated
   */
  EClass getLendable();

  /**
   * Returns the meta object for the attribute '{@link org.example.library.Lendable#getLoanDays <em>Loan Days</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute '<em>Loan Days</em>'.
   * @see org.example.library.Lendable#getLoanDays()
   * @see #getLendable()
   * @generated
   */
  EAttribute getLendable_LoanDays();

  /**
   * Returns the meta object for the attribute '{@link org.example.library.Lendable#isOnLoan <em>On Loan</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute '<em>On Loan</em>'.
   * @see org.example.library.Lendable#isOnLoan()
   * @see #getLendable()
   * @generated
   */
  EAttribute getLendable_OnLoan();

  /**
   * Returns the meta object for class '{@link org.example.library.Book <em>Book</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for class '<em>Book</em>'.
   * @see org.example.library.Book
   * @generated
   */
  EClass getBook();

  /**
   * Returns the meta object for the attribute '{@link org.example.library.Book#getPages <em>Pages</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute '<em>Pages</em>'.
   * @see org.example.library.Book#getPages()
   * @see #getBook()
   * @generated
   */
  EAttribute getBook_Pages();

  /**
   * Returns the meta object for the attribute '{@link org.example.library.Book#getCategory <em>Category</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute '<em>Category</em>'.
   * @see org.example.library.Book#getCategory()
   * @see #getBook()
   * @generated
   */
  EAttribute getBook_Category();

  /**
   * Returns the meta object for the attribute '{@link org.example.library.Book#getIsbn <em>Isbn</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute '<em>Isbn</em>'.
   * @see org.example.library.Book#getIsbn()
   * @see #getBook()
   * @generated
   */
  EAttribute getBook_Isbn();

  /**
   * Returns the meta object for the reference '{@link org.example.library.Book#getAuthor <em>Author</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the reference '<em>Author</em>'.
   * @see org.example.library.Book#getAuthor()
   * @see #getBook()
   * @generated
   */
  EReference getBook_Author();

  /**
   * Returns the meta object for the container reference '{@link org.example.library.Book#getLibrary <em>Library</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the container reference '<em>Library</em>'.
   * @see org.example.library.Book#getLibrary()
   * @see #getBook()
   * @generated
   */
  EReference getBook_Library();

  /**
   * Returns the meta object for class '{@link org.example.library.Writer <em>Writer</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for class '<em>Writer</em>'.
   * @see org.example.library.Writer
   * @generated
   */
  EClass getWriter();

  /**
   * Returns the meta object for the attribute list '{@link org.example.library.Writer#getAliases <em>Aliases</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the attribute list '<em>Aliases</em>'.
   * @see org.example.library.Writer#getAliases()
   * @see #getWriter()
   * @generated
   */
  EAttribute getWriter_Aliases();

  /**
   * Returns the meta object for the reference list '{@link org.example.library.Writer#getBooks <em>Books</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the reference list '<em>Books</em>'.
   * @see org.example.library.Writer#getBooks()
   * @see #getWriter()
   * @generated
   */
  EReference getWriter_Books();

  /**
   * Returns the meta object for class '{@link org.example.library.Library <em>Library</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for class '<em>Library</em>'.
   * @see org.example.library.Library
   * @generated
   */
  EClass getLibrary();

  /**
   * Returns the meta object for the containment reference list '{@link org.example.library.Library#getBooks <em>Books</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the containment reference list '<em>Books</em>'.
   * @see org.example.library.Library#getBooks()
   * @see #getLibrary()
   * @generated
   */
  EReference getLibrary_Books();

  /**
   * Returns the meta object for the containment reference list '{@link org.example.library.Library#getWriters <em>Writers</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the containment reference list '<em>Writers</em>'.
   * @see org.example.library.Library#getWriters()
   * @see #getLibrary()
   * @generated
   */
  EReference getLibrary_Writers();

  /**
   * Returns the meta object for the '{@link org.example.library.Library#findBooks(java.lang.String, int) <em>Find Books</em>}' operation.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for the '<em>Find Books</em>' operation.
   * @see org.example.library.Library#findBooks(java.lang.String, int)
   * @generated
   */
  EOperation getLibrary__FindBooks__String_int();

  /**
   * Returns the meta object for enum '{@link org.example.library.BookCategory <em>Book Category</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for enum '<em>Book Category</em>'.
   * @see org.example.library.BookCategory
   * @generated
   */
  EEnum getBookCategory();

  /**
   * Returns the meta object for data type '{@link java.lang.String <em>ISBN</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the meta object for data type '<em>ISBN</em>'.
   * @see java.lang.String
 * @model instanceClass="java.lang.String"
   * @generated
   */
  EDataType getISBN();

  /**
   * Returns the factory that creates the instances of the model.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the factory that creates the instances of the model.
   * @generated
   */
  LibraryFactory getLibraryFactory();

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
     * The meta object literal for the '{@link org.example.library.impl.NamedImpl <em>Named</em>}' class.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see org.example.library.impl.NamedImpl
     * @see org.example.library.impl.LibraryPackageImpl#getNamed()
     * @generated
     */
    EClass NAMED = eINSTANCE.getNamed();

    /**
     * The meta object literal for the '<em><b>Name</b></em>' attribute feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute NAMED__NAME = eINSTANCE.getNamed_Name();

    /**
     * The meta object literal for the '{@link org.example.library.Lendable <em>Lendable</em>}' class.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see org.example.library.Lendable
     * @see org.example.library.impl.LibraryPackageImpl#getLendable()
     * @generated
     */
    EClass LENDABLE = eINSTANCE.getLendable();

    /**
     * The meta object literal for the '<em><b>Loan Days</b></em>' attribute feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute LENDABLE__LOAN_DAYS = eINSTANCE.getLendable_LoanDays();

    /**
     * The meta object literal for the '<em><b>On Loan</b></em>' attribute feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute LENDABLE__ON_LOAN = eINSTANCE.getLendable_OnLoan();

    /**
     * The meta object literal for the '{@link org.example.library.impl.BookImpl <em>Book</em>}' class.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see org.example.library.impl.BookImpl
     * @see org.example.library.impl.LibraryPackageImpl#getBook()
     * @generated
     */
    EClass BOOK = eINSTANCE.getBook();

    /**
     * The meta object literal for the '<em><b>Pages</b></em>' attribute feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute BOOK__PAGES = eINSTANCE.getBook_Pages();

    /**
     * The meta object literal for the '<em><b>Category</b></em>' attribute feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute BOOK__CATEGORY = eINSTANCE.getBook_Category();

    /**
     * The meta object literal for the '<em><b>Isbn</b></em>' attribute feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute BOOK__ISBN = eINSTANCE.getBook_Isbn();

    /**
     * The meta object literal for the '<em><b>Author</b></em>' reference feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EReference BOOK__AUTHOR = eINSTANCE.getBook_Author();

    /**
     * The meta object literal for the '<em><b>Library</b></em>' container reference feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EReference BOOK__LIBRARY = eINSTANCE.getBook_Library();

    /**
     * The meta object literal for the '{@link org.example.library.impl.WriterImpl <em>Writer</em>}' class.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see org.example.library.impl.WriterImpl
     * @see org.example.library.impl.LibraryPackageImpl#getWriter()
     * @generated
     */
    EClass WRITER = eINSTANCE.getWriter();

    /**
     * The meta object literal for the '<em><b>Aliases</b></em>' attribute list feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EAttribute WRITER__ALIASES = eINSTANCE.getWriter_Aliases();

    /**
     * The meta object literal for the '<em><b>Books</b></em>' reference list feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EReference WRITER__BOOKS = eINSTANCE.getWriter_Books();

    /**
     * The meta object literal for the '{@link org.example.library.impl.LibraryImpl <em>Library</em>}' class.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see org.example.library.impl.LibraryImpl
     * @see org.example.library.impl.LibraryPackageImpl#getLibrary()
     * @generated
     */
    EClass LIBRARY = eINSTANCE.getLibrary();

    /**
     * The meta object literal for the '<em><b>Books</b></em>' containment reference list feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EReference LIBRARY__BOOKS = eINSTANCE.getLibrary_Books();

    /**
     * The meta object literal for the '<em><b>Writers</b></em>' containment reference list feature.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EReference LIBRARY__WRITERS = eINSTANCE.getLibrary_Writers();

    /**
     * The meta object literal for the '<em><b>Find Books</b></em>' operation.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @generated
     */
    EOperation LIBRARY___FIND_BOOKS__STRING_INT = eINSTANCE.getLibrary__FindBooks__String_int();

    /**
     * The meta object literal for the '{@link org.example.library.BookCategory <em>Book Category</em>}' enum.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see org.example.library.BookCategory
     * @see org.example.library.impl.LibraryPackageImpl#getBookCategory()
     * @generated
     */
    EEnum BOOK_CATEGORY = eINSTANCE.getBookCategory();

    /**
     * The meta object literal for the '<em>ISBN</em>' data type.
     * <!-- begin-user-doc -->
     * <!-- end-user-doc -->
     * @see java.lang.String
     * @see org.example.library.impl.LibraryPackageImpl#getISBN()
     * @generated
     */
    EDataType ISBN = eINSTANCE.getISBN();

  }

} //LibraryPackage
