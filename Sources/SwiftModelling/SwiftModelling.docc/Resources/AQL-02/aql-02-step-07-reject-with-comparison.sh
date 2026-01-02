#!/bin/bash
# AQL-02 Step 7: Reject with Comparison Operators

echo "=== AQL Filtering: Reject with Comparisons ==="
echo ""
echo "Reject operations can use the same comparison operators as select."
echo ""

echo "Reject students below grade threshold:"
echo "  AQL: university.students->reject(s | s.grade < 80)"
echo "  Returns: Only students with 80 or higher"
echo "  Equivalent to: select(s | s.grade >= 80)"
echo "  Result: 8 students with grades 80+"
echo ""

echo "Reject young students:"
echo "  AQL: university.students->reject(s | s.age < 20)"
echo "  Returns: Students 20 or older"
echo "  Result: [John Doe (20), Jane Smith (21), Alice Williams (22),"
echo "           Charlie Brown (20), Diana Prince (21), Frank Miller (23),"
echo "           Grace Lee (20), Ivy Chen (22)]"
echo ""

echo "Reject high-credit courses:"
echo "  AQL: university.courses->reject(c | c.credits > 3)"
echo "  Returns: Only 3-credit courses"
echo "  Result: [Introduction to Physics, Organic Chemistry, English Literature]"
echo ""

echo "Reject with combined conditions:"
echo "  AQL: university.professors->reject(p | p.age >= 50 or p.tenure = false)"
echo "  Returns: Tenured professors under 50"
echo "  Result: [Dr. Alan Turing (45), Dr. Ada Lovelace (42), Dr. Dorothy Hodgkin (48)]"
echo ""

echo "When to use reject instead of select:"
echo "  - When the negative condition is simpler to express"
echo "  - When you want to 'filter out' rather than 'filter in'"
echo "  - For code readability ('reject invalid' vs 'select valid')"
echo ""

echo "✅ Reject is select's logical complement"
