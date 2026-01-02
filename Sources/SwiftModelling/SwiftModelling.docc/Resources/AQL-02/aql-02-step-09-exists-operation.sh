#!/bin/bash
# AQL-02 Step 9: Exists Operation

echo "=== AQL Filtering: Exists Quantifier ==="
echo ""
echo "The exists operation checks if AT LEAST ONE element matches a condition."
echo "Returns: Boolean (true/false)"
echo ""

echo "Example 1: Check if any student has grade >= 95"
echo "  AQL: university.students->exists(s | s.grade >= 95)"
echo "  Returns: true"
echo "  Reason: Charlie Brown (95) and Ivy Chen (94... wait, 94 < 95)"
echo "  Correct: Charlie Brown has 95, so true"
echo ""

echo "Example 2: Check if any course is worth 5 credits"
echo "  AQL: university.courses->exists(c | c.credits = 5)"
echo "  Returns: false"
echo "  Reason: All courses are either 3 or 4 credits"
echo ""

echo "Example 3: Check if any professor specialises in Physics"
echo "  AQL: university.professors->exists(p | p.specialisation = 'Physics')"
echo "  Returns: true"
echo "  Reason: Dr. Marie Curie and Dr. Richard Feynman"
echo ""

echo "Example 4: Complex condition"
echo "  AQL: university.students->exists(s | s.age < 19 and s.grade > 80)"
echo "  Returns: false"
echo "  Reason: Henry Wilson is 18 but has grade 65"
echo "           Other high-performers are 19 or older"
echo ""

echo "Using exists in conditional logic:"
echo "  AQL:"
echo "    if university.students->exists(s | s.grade < 60) then"
echo "      'Warning: Students at risk'"
echo "    else"
echo "      'All students passing'"
echo "    endif"
echo ""

echo "Exists vs. Select:"
echo "  exists: Returns boolean (did we find any?)"
echo "  select: Returns collection (give me all that match)"
echo ""
echo "  exists is more efficient when you only need yes/no"
echo ""

echo "✅ Exists checks for AT LEAST ONE match"
