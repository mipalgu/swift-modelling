#!/bin/bash
# AQL-02 Step 10: ForAll Operation

echo "=== AQL Filtering: ForAll Quantifier ==="
echo ""
echo "The forAll operation checks if ALL elements match a condition."
echo "Returns: Boolean (true/false)"
echo ""

echo "Example 1: Check if all students are passing (grade >= 60)"
echo "  AQL: university.students->forAll(s | s.grade >= 60)"
echo "  Returns: true"
echo "  Reason: Lowest grade is Henry Wilson with 65"
echo ""

echo "Example 2: Check if all courses are 4 credits"
echo "  AQL: university.courses->forAll(c | c.credits = 4)"
echo "  Returns: false"
echo "  Reason: Some courses are 3 credits (Physics, Chemistry, English Lit)"
echo ""

echo "Example 3: Check if all professors have tenure"
echo "  AQL: university.professors->forAll(p | p.tenure = true)"
echo "  Returns: false"
echo "  Reason: Dr. Richard Feynman doesn't have tenure"
echo ""

echo "Example 4: Validate data integrity"
echo "  AQL: university.students->forAll(s | s.age > 0 and s.grade >= 0 and s.grade <= 100)"
echo "  Returns: true"
echo "  Purpose: Ensure all student data is valid"
echo ""

echo "Using forAll for validation:"
echo "  AQL:"
echo "    if not university.courses->forAll(c | c.credits > 0) then"
echo "      'Error: Invalid course credits'"
echo "    else"
echo "      'All courses valid'"
echo "    endif"
echo ""

echo "ForAll vs. Exists:"
echo "  forAll: ALL must match (universal quantifier ∀)"
echo "  exists: AT LEAST ONE must match (existential quantifier ∃)"
echo ""

echo "Empty collection behaviour:"
echo "  Sequence{}->forAll(condition) = true (vacuous truth)"
echo "  Sequence{}->exists(condition) = false (no elements to match)"
echo ""

echo "Combining with negation:"
echo "  'No students failed' ="
echo "    university.students->forAll(s | s.grade >= 60)"
echo "  OR"
echo "    not university.students->exists(s | s.grade < 60)"
echo ""

echo "✅ ForAll checks if ALL elements match"
