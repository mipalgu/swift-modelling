/**
 * Copyright 2026 Example Pty Ltd
 */
package org.example.library;


/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Book</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link org.example.library.Book#getPages <em>Pages</em>}</li>
 *   <li>{@link org.example.library.Book#getCategory <em>Category</em>}</li>
 *   <li>{@link org.example.library.Book#getIsbn <em>Isbn</em>}</li>
 *   <li>{@link org.example.library.Book#getAuthor <em>Author</em>}</li>
 *   <li>{@link org.example.library.Book#getLibrary <em>Library</em>}</li>
 * </ul>
 *
 * @see org.example.library.LibraryPackage#getBook()
 * @model
 * @generated
 */
public interface Book extends Named, Lendable
{
  /**
   * Returns the value of the '<em><b>Pages</b></em>' attribute.
   * The default value is <code>"100"</code>.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Pages</em>' attribute.
   * @see #setPages(int)
   * @see org.example.library.LibraryPackage#getBook_Pages()
   * @model default="100"
   * @generated
   */
  int getPages();

  /**
   * Sets the value of the '{@link org.example.library.Book#getPages <em>Pages</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Pages</em>' attribute.
   * @see #getPages()
   * @generated
   */
  void setPages(int value);

  /**
   * Returns the value of the '<em><b>Category</b></em>' attribute.
   * The literals are from the enumeration {@link org.example.library.BookCategory}.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Category</em>' attribute.
   * @see org.example.library.BookCategory
   * @see #setCategory(BookCategory)
   * @see org.example.library.LibraryPackage#getBook_Category()
   * @model
   * @generated
   */
  BookCategory getCategory();

  /**
   * Sets the value of the '{@link org.example.library.Book#getCategory <em>Category</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Category</em>' attribute.
   * @see org.example.library.BookCategory
   * @see #getCategory()
   * @generated
   */
  void setCategory(BookCategory value);

  /**
   * Returns the value of the '<em><b>Isbn</b></em>' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Isbn</em>' attribute.
   * @see #setIsbn(String)
   * @see org.example.library.LibraryPackage#getBook_Isbn()
   * @model dataType="org.example.library.ISBN"
   * @generated
   */
  String getIsbn();

  /**
   * Sets the value of the '{@link org.example.library.Book#getIsbn <em>Isbn</em>}' attribute.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Isbn</em>' attribute.
   * @see #getIsbn()
   * @generated
   */
  void setIsbn(String value);

  /**
   * Returns the value of the '<em><b>Author</b></em>' reference.
   * It is bidirectional and its opposite is '{@link org.example.library.Writer#getBooks <em>Books</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Author</em>' reference.
   * @see #setAuthor(Writer)
   * @see org.example.library.LibraryPackage#getBook_Author()
   * @see org.example.library.Writer#getBooks
   * @model opposite="books" required="true"
   * @generated
   */
  Writer getAuthor();

  /**
   * Sets the value of the '{@link org.example.library.Book#getAuthor <em>Author</em>}' reference.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Author</em>' reference.
   * @see #getAuthor()
   * @generated
   */
  void setAuthor(Writer value);

  /**
   * Returns the value of the '<em><b>Library</b></em>' container reference.
   * It is bidirectional and its opposite is '{@link org.example.library.Library#getBooks <em>Books</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Library</em>' container reference.
   * @see #setLibrary(Library)
   * @see org.example.library.LibraryPackage#getBook_Library()
   * @see org.example.library.Library#getBooks
   * @model opposite="books" transient="false"
   * @generated
   */
  Library getLibrary();

  /**
   * Sets the value of the '{@link org.example.library.Book#getLibrary <em>Library</em>}' container reference.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @param value the new value of the '<em>Library</em>' container reference.
   * @see #getLibrary()
   * @generated
   */
  void setLibrary(Library value);

} // Book
