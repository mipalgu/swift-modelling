/**
 * Copyright 2026 Example Pty Ltd
 */
package org.example.library;


import org.eclipse.emf.common.util.EList;


/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Writer</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link org.example.library.Writer#getAliases <em>Aliases</em>}</li>
 *   <li>{@link org.example.library.Writer#getBooks <em>Books</em>}</li>
 * </ul>
 *
 * @see org.example.library.LibraryPackage#getWriter()
 * @model
 * @generated
 */
public interface Writer extends Named
{
  /**
   * Returns the value of the '<em><b>Aliases</b></em>' attribute list.
   * The list contents are of type {@link java.lang.String}.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Aliases</em>' attribute list.
   * @see org.example.library.LibraryPackage#getWriter_Aliases()
   * @model
   * @generated
   */
  EList<String> getAliases();

  /**
   * Returns the value of the '<em><b>Books</b></em>' reference list.
   * The list contents are of type {@link org.example.library.Book}.
   * It is bidirectional and its opposite is '{@link org.example.library.Book#getAuthor <em>Author</em>}'.
   * <!-- begin-user-doc -->
   * <!-- end-user-doc -->
   * @return the value of the '<em>Books</em>' reference list.
   * @see org.example.library.LibraryPackage#getWriter_Books()
   * @see org.example.library.Book#getAuthor
   * @model opposite="author"
   * @generated
   */
  EList<Book> getBooks();

} // Writer
