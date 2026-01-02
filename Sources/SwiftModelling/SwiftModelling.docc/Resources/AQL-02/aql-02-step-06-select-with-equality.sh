#!/bin/bash
# AQL-02 Step 6: Select with Equality Operators

echo "=== AQL Filtering: Select with Equality ==="
echo ""
echo "Use equality operators for exact matching."
echo ""

echo "Equality (=) for strings:"
echo "  AQL: university.courses->select(c | c.department = 'Computer Science')"
echo "  Returns: All CS courses"
echo "  Result: [Data Structures, Algorithms]"
echo ""

echo "Equality (=) for numbers:"
echo "  AQL: university.students->select(s | s.age = 20)"
echo "  Returns: All 20-year-old students"
echo "  Result: [John Doe, Charlie Brown, Grace Lee]"
echo ""

echo "Inequality (<>) for strings:"
echo "  AQL: university.courses->select(c | c.department <> 'Physics')"
echo "  Returns: All non-Physics courses"
echo "  Result: [Data Structures, Algorithms, Calculus I, Calculus II,"
echo "           Organic Chemistry, English Literature]"
echo ""

echo "Inequality (<>) for booleans:"
echo "  AQL: university.professors->select(p | p.tenure <> true)"
echo "  Alternative: university.professors->select(p | not p.tenure)"
echo "  Returns: Non-tenured professors"
echo "  Result: [Dr. Richard Feynman]"
echo ""

echo "Combining equality with other conditions:"
echo "  AQL: university.students->select(s | s.department = 'Mathematics' and s.grade >= 85)"
echo "  Note: This would work if students had a department attribute"
echo ""

echo "Case sensitivity note:"
echo "  String comparisons are case-sensitive in AQL"
echo "  'computer science' <> 'Computer Science'"
echo "  Use .toLowerCase() or .toUpperCase() for case-insensitive matching"
echo ""

echo "✅ Equality operators enable exact value matching"
