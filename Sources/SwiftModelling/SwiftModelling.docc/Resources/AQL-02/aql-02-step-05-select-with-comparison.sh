#!/bin/bash
# AQL-02 Step 5: Select with Comparison Operators

echo "=== AQL Filtering: Select with Comparisons ==="
echo ""
echo "Use comparison operators in select conditions for numeric filtering."
echo ""

echo "Greater than (>):"
echo "  AQL: university.students->select(s | s.grade > 90)"
echo "  Returns: Students with grade strictly greater than 90"
echo "  Result: [Jane Smith (92), Charlie Brown (95), Ivy Chen (94)]"
echo ""

echo "Greater than or equal (>=):"
echo "  AQL: university.students->select(s | s.age >= 21)"
echo "  Returns: Students 21 or older"
echo "  Result: [Jane Smith (21), Alice Williams (22), Diana Prince (21),"
echo "           Frank Miller (23), Ivy Chen (22)]"
echo ""

echo "Less than (<):"
echo "  AQL: university.professors->select(p | p.age < 45)"
echo "  Returns: Professors younger than 45"
echo "  Result: [Dr. Ada Lovelace (42), Dr. Richard Feynman (38)]"
echo ""

echo "Less than or equal (<=):"
echo "  AQL: university.students->select(s | s.grade <= 75)"
echo "  Returns: Students with failing or near-failing grades"
echo "  Result: [Henry Wilson (65), Jack Taylor (72)]"
echo ""

echo "Multiple conditions with 'and':"
echo "  AQL: university.students->select(s | s.grade >= 85 and s.age <= 20)"
echo "  Returns: High-performing students 20 or younger"
echo "  Result: [John Doe (85, 20), Charlie Brown (95, 20), Grace Lee (87, 20)]"
echo ""

echo "Multiple conditions with 'or':"
echo "  AQL: university.students->select(s | s.grade >= 95 or s.age >= 23)"
echo "  Returns: Either exceptional students or older students"
echo "  Result: [Charlie Brown (95), Frank Miller (90, 23), Ivy Chen (94)]"
echo ""

echo "✅ Comparison operators enable precise numeric filtering"
