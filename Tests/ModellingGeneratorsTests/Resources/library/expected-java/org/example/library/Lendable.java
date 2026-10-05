/**
 * Copyright 2026 Example Pty Ltd
 */
package org.example.library;

import org.eclipse.emf.ecore.EObject;

/**
 * <!-- begin-user-doc -->
 * A representation of the model object '<em><b>Lendable</b></em>'.
 * <!-- end-user-doc -->
 *
 * <p>
 * The following features are supported:
 * </p>
 * <ul>
 *   <li>{@link org.example.library.Lendable#getLoanDays <em>Loan Days</em>}</li>
 *   <li>{@link org.example.library.Lendable#isOnLoan <em>On Loan</em>}</li>
 * </ul>
 *
 * @see org.example.library.LibraryPackage#getLendable()
 * @model interface="true" abstract="true"
 * @generated
 */
public interface Lendable extends EObject {
	/**
	 * Returns the value of the '<em><b>Loan Days</b></em>' attribute.
	 * The default value is <code>"14"</code>.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>Loan Days</em>' attribute.
	 * @see #setLoanDays(int)
	 * @see org.example.library.LibraryPackage#getLendable_LoanDays()
	 * @model default="14"
	 * @generated
	 */
	int getLoanDays();

	/**
	 * Sets the value of the '{@link org.example.library.Lendable#getLoanDays <em>Loan Days</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>Loan Days</em>' attribute.
	 * @see #getLoanDays()
	 * @generated
	 */
	void setLoanDays(int value);

	/**
	 * Returns the value of the '<em><b>On Loan</b></em>' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @return the value of the '<em>On Loan</em>' attribute.
	 * @see #setOnLoan(boolean)
	 * @see org.example.library.LibraryPackage#getLendable_OnLoan()
	 * @model
	 * @generated
	 */
	boolean isOnLoan();

	/**
	 * Sets the value of the '{@link org.example.library.Lendable#isOnLoan <em>On Loan</em>}' attribute.
	 * <!-- begin-user-doc -->
	 * <!-- end-user-doc -->
	 * @param value the new value of the '<em>On Loan</em>' attribute.
	 * @see #isOnLoan()
	 * @generated
	 */
	void setOnLoan(boolean value);

} // Lendable
