#!/bin/bash
# AQL-02 Step 4: Simple Reject Operation

echo "=== AQL Filtering: Simple Reject ==="
echo ""
echo "The reject operation filters OUT elements that match a condition."
echo "It's the opposite of select."
echo ""

echo "Example 1: Reject students with low grades (< 80)"
echo "  AQL: university.students->reject(s | s.grade < 80)"
echo "  Returns: Students with grades 80 or higher"
echo "  Result: [John Doe (85), Jane Smith (92), Alice Williams (88),"
echo "           Charlie Brown (95), Diana Prince (82), Frank Miller (90),"
echo "           Grace Lee (87), Ivy Chen (94)]"
echo ""

echo "Example 2: Reject 3-credit courses"
echo "  AQL: university.courses->reject(c | c.credits = 3)"
echo "  Returns: All courses NOT worth 3 credits (i.e., 4-credit courses)"
echo "  Result: [Data Structures, Algorithms, Calculus I, Calculus II, Quantum Mechanics]"
echo ""

echo "Example 3: Reject non-tenured professors"
echo "  AQL: university.professors->reject(p | p.tenure = false)"
echo "  Returns: Only tenured professors"
echo "  Result: [Dr. Alan Turing, Dr. Ada Lovelace, Dr. Marie Curie, Dr. Dorothy Hodgkin]"
echo ""

echo "Reject operation syntax:"
echo "  collection->reject(variable | condition)"
echo ""

echo "Relationship between select and reject:"
echo "  select(condition) ≡ reject(not condition)"
echo ""
echo "  university.students->select(s | s.grade >= 80)"
echo "  is equivalent to:"
echo "  university.students->reject(s | s.grade < 80)"
echo ""

echo "✅ Reject filters OUT elements that match the condition"
