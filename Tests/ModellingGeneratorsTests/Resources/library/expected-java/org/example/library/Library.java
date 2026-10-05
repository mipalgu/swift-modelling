/**
 * Copyright 2026 Example Pty Ltd
 */
package org.example.library;

import org.eclipse.emf.common.util.EList;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Library</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link org.example.library.Library#getBooks <em>Books</em>}</li>
 *   <li>{@link org.example.library.Library#getWriters <em>Writers</em>}</li>
 * </ul>
 *
 * @see org.example.library.LibraryPackage#getLibrary()
 * @model
 * @generated
 */
public interface Library extends Named {
	/**
	 * Returns the value of the '<em><b>Books</b></em>' containment reference list.
	 * The list contents are of type {@link org.example.library.Book}.
	 * It is bidirectional and its opposite is '{@link org.example.library.Book#getLibrary <em>Library</em>}'.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Books</em>' containment reference list.
	 * @see org.example.library.LibraryPackage#getLibrary_Books()
	 * @see org.example.library.Book#getLibrary
	 * @model opposite="library" containment="true"
	 * @generated
	 */
	EList<Book> getBooks();

	/**
	 * Returns the value of the '<em><b>Writers</b></em>' containment reference list.
	 * The list contents are of type {@link org.example.library.Writer}.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Writers</em>' containment reference list.
	 * @see org.example.library.LibraryPackage#getLibrary_Writers()
	 * @model containment="true"
	 * @generated
	 */
	EList<Writer> getWriters();

	/**
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @model
	 * @generated
	 */
	EList<Book> findBooks(String title, int maxResults);

} // Library
