#!/bin/bash
# AQL-02 Step 3: Simple Select Operation

echo "=== AQL Filtering: Simple Select ==="
echo ""
echo "The select operation filters a collection based on a condition."
echo ""

echo "Example 1: Select students with high grades (>= 85)"
echo "  AQL: university.students->select(s | s.grade >= 85)"
echo "  Returns: Students with grades 85 or higher"
echo "  Result: [John Doe (85), Jane Smith (92), Alice Williams (88),"
echo "           Charlie Brown (95), Diana Prince (82), Frank Miller (90),"
echo "           Grace Lee (87), Ivy Chen (94)]"
echo ""

echo "Example 2: Select 4-credit courses"
echo "  AQL: university.courses->select(c | c.credits = 4)"
echo "  Returns: All courses worth 4 credits"
echo "  Result: [Data Structures, Algorithms, Calculus I, Calculus II, Quantum Mechanics]"
echo ""

echo "Example 3: Select tenured professors"
echo "  AQL: university.professors->select(p | p.tenure = true)"
echo "  Returns: Professors with tenure"
echo "  Result: [Dr. Alan Turing, Dr. Ada Lovelace, Dr. Marie Curie, Dr. Dorothy Hodgkin]"
echo ""

echo "Select operation syntax:"
echo "  collection->select(variable | condition)"
echo ""
echo "Where:"
echo "  - collection: The source collection"
echo "  - variable: Temporary variable for each element (e.g., 's', 'c', 'p')"
echo "  - condition: Boolean expression that must be true"
echo "  - |: Separates the variable from the condition (lambda syntax)"
echo ""

echo "✅ Select filters IN elements that match the condition"
