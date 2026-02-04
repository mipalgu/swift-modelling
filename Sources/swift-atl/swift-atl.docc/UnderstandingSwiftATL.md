# Understanding swift-atl

Learn the key concepts behind the swift-atl command-line tool.

## Overview

The swift-atl CLI tool executes ATL (Atlas Transformation
Language) transformations that convert models from one metamodel
to another. Understanding transformation rules, execution phases,
and helper operations is essential for creating effective
model-to-model transformations.

## Model Transformation

### What is Model Transformation?

Model transformation converts a source model conforming to one
metamodel into a target model conforming to another metamodel:

```
Source Model (IN)      Transform      Target Model (OUT)
families.xmi       ──────────────>   persons.xmi
  (Families MM)                        (Persons MM)
```

Transformations are declarative - you specify **what** should be
created, not **how** to create it. The ATL engine handles
execution order and reference resolution.

### Transformation Declaration

Every transformation declares its models:

```atl
module Families2Persons;
create OUT: Persons from IN: Families;
```

This specifies:
- `OUT` - Name of the target model
- `Persons` - Target metamodel
- `IN` - Name of the source model
- `Families` - Source metamodel

## Rule Types

### Matched Rules

Matched rules automatically apply to matching source elements:

```atl
rule Member2Male {
    from
        s: Families!Member (not s.isFemale())
    to
        t: Persons!Male (
            fullName <- s.firstName + ' ' + s.familyName
        )
}
```

The ATL engine:
1. Finds all `Families!Member` instances
2. Tests each against the guard `(not s.isFemale())`
3. Creates `Persons!Male` for matches
4. Sets bindings (`fullName <- ...`)

**When to use**: Default choice for most transformations. Use when
you want elements transformed automatically based on their type
and properties.

### Lazy Rules

Lazy rules execute only when explicitly called:

```atl
lazy rule CreateAddress {
    from
        m: Families!Member
    to
        a: Persons!Address (
            street <- m.street,
            city <- m.city
        )
}
```

Call with `thisModule.RuleName(sourceElement)`:

```atl
rule Member2Person {
    from
        m: Families!Member
    to
        p: Persons!Person (
            address <- thisModule.CreateAddress(m)
        )
}
```

**When to use**: On-demand element creation, conditional
instantiation, or when multiple rules might create the same type.

**Caching**: Lazy rules cache results - calling with the same
source element returns the same target element.

### Called Rules

Called rules take parameters and return created elements:

```atl
called rule CreatePerson(name: String, age: Integer) {
    to
        p: Persons!Person (
            name <- name,
            age <- age
        )
    do {
        p;
    }
}
```

Call from other rules:

```atl
rule Family2Household {
    from
        f: Families!Family
    to
        h: Persons!Household (
            members <- f.members->collect(m |
                thisModule.CreatePerson(m.firstName, m.age))
        )
}
```

**When to use**: Parameterised element creation, when source
elements don't directly map to target elements, or for imperative
logic.

**No caching**: Called rules don't cache - each call creates new
elements.

## Helpers

### Context Helpers

Context helpers add operations to metamodel classes:

```atl
helper context Families!Member def: fullName: String =
    self.firstName + ' ' + self.familyName;

helper context Families!Family def: allMembers: Sequence(Member) =
    self.father->union(self.mother)
         ->union(self.sons)->union(self.daughters);
```

Call on elements of that type:

```atl
to
    p: Persons!Person (
        name <- s.fullName,
        familySize <- s.family.allMembers->size()
    )
```

**When to use**: Reusable queries specific to a metamodel class.

### Module Helpers

Module helpers are utility functions:

```atl
helper def: isAdult(age: Integer): Boolean =
    age >= 18;

helper def: normalise(s: String): String =
    s.toLower().replaceAll(' ', '_');
```

Call via `thisModule`:

```atl
to
    p: Persons!Person (
        name <- thisModule.normalise(s.name),
        isAdult <- thisModule.isAdult(s.age)
    )
```

**When to use**: Utility operations not tied to specific classes.

## Execution Model

### Phases

ATL executes in distinct phases:

**1. Matching Phase**

The engine evaluates all matched rules against source elements:
- Tests guards for each rule/element pair
- Records which rules apply to which elements
- Builds execution schedule

**2. Creation Phase**

Target elements are instantiated:
- One target element per rule application
- Elements created but not initialised
- Trace links recorded (source → target mapping)

**3. Initialisation Phase**

Target element features are set:
- Bindings evaluated left-to-right
- References resolved via trace links
- Helpers and expressions computed

**4. Finalisation Phase**

Post-processing completes:
- Lazy rules may execute if called
- Called rules execute as invoked
- Cross-references fully resolved

### Trace Model

The trace model links source and target elements:

```
Source Element         Trace Link         Target Element
Families!Member    ──────────────────>  Persons!Male
  (John Smith)                            (John Smith)
```

Used for:
- Reference resolution
- `resolveTemp()` lookups
- Debugging transformation execution

When you reference a source element in a binding, ATL uses the
trace to find the corresponding target element:

```atl
to
    h: Persons!Household (
        owner <- s.father  -- Resolves to target element created from father
    )
```

## Reference Resolution

### Automatic Resolution

Simple references resolve automatically:

```atl
rule Family2Household {
    from
        f: Families!Family
    to
        h: Persons!Household (
            owner <- f.father,           -- Resolves to Person created from father
            members <- f.allMembers      -- Resolves all members
        )
}
```

ATL looks up each source element in the trace and uses the
corresponding target element.

### Manual Resolution

Use `resolveTemp` for explicit control:

```atl
to
    h: Persons!Household (
        owner <- thisModule.resolveTemp(f.father, 'p')
    )
```

The second argument is the output pattern element name from the
rule that created it.

## Guards and Filters

### Rule Guards

Guards filter which elements a rule applies to:

```atl
rule Member2Male {
    from
        s: Families!Member (
            not s.isFemale() and
            s.age >= 18
        )
    to
        t: Persons!Male (...)
}
```

Only `Member` instances satisfying the guard are transformed.

### Collection Filters

OCL operations filter collections in bindings:

```atl
to
    h: Persons!Household (
        adults <- f.members->select(m | m.age >= 18),
        children <- f.members->reject(m | m.age >= 18),
        names <- f.members->collect(m | m.firstName)
    )
```

Common operations:
- `select(condition)` - Keep matching elements
- `reject(condition)` - Exclude matching elements
- `collect(expression)` - Transform each element

## Compilation and Optimisation

### Bytecode Compilation

Compile transformations to bytecode:

```bash
swift-atl compile MyTransformation.atl --optimise
```

Creates `MyTransformation.asm` with optimised bytecode.

**Benefits:**
- Faster execution (5-10× speedup typical)
- Parse happens once
- Type checking cached
- Optimisation passes applied

**Use when:**
- Running transformations repeatedly
- Processing large models
- Production deployments
- Batch processing

### Optimisation Passes

The `--optimise` flag enables:
- Constant folding
- Dead code elimination
- Helper inlining
- Loop unrolling
- Common subexpression elimination

## Execution Modes

### Normal Mode

Default mode for production use:

```bash
swift-atl transform Transform.atl \
    --source input.xmi \
    --target output.xmi
```

Prints only errors and warnings.

### Debug Mode

Detailed execution tracing:

```bash
swift-atl transform Transform.atl \
    --source input.xmi \
    --target output.xmi \
    --mode debug \
    --verbose
```

Shows:
- Rule matching decisions
- Guard evaluation results
- Binding assignments
- Helper calls and returns
- Trace links

**Use for**: Development, debugging, understanding execution.

### Trace Mode

Maximum detail for deep debugging:

```bash
swift-atl transform Transform.atl \
    --source input.xmi \
    --target output.xmi \
    --mode trace
```

Includes everything from debug mode plus:
- Expression evaluation steps
- OCL operation details
- Memory allocation
- Performance timings

**Use for**: Diagnosing complex issues, performance profiling.

## Validation

### Syntax Validation

Check transformation syntax:

```bash
swift-atl validate MyTransformation.atl
```

Verifies:
- ATL syntax correctness
- Well-formed expressions
- Helper signatures
- Rule structure

### Semantic Validation

Validate against metamodels:

```bash
swift-atl validate MyTransformation.atl \
    --source-metamodel Source.ecore \
    --target-metamodel Target.ecore \
    --strict
```

Verifies:
- Referenced classes exist
- Attributes and references are valid
- Type compatibility
- Cardinality constraints

**Always validate** before running transformations on production
data.

## Best Practices

### Design Transformations Incrementally

Start simple, add complexity gradually:

1. Create matched rules for main concepts
2. Test with small sample models
3. Add guards to refine matching
4. Introduce helpers for complex queries
5. Add lazy/called rules as needed

### Use Meaningful Names

Clear names improve maintainability:

```atl
-- Good
rule Member2Person { ... }
helper context Member def: fullName: String = ...

-- Unclear
rule M2P { ... }
helper context Member def: fn: String = ...
```

### Validate at Transformation Boundaries

Always validate inputs and outputs:

```bash
#!/bin/bash
# Validate input
swift-ecore validate input.xmi --metamodel Source.ecore || exit 1

# Transform
swift-atl transform Transform.atl \
    --source input.xmi \
    --target output.xmi

# Validate output
swift-ecore validate output.xmi --metamodel Target.ecore
```

### Extract Complex Logic to Helpers

Don't embed complex expressions in bindings:

```atl
-- Better
helper context Family def: adultMembers: Sequence(Member) =
    self.members->select(m | m.age >= 18 and not m.isRetired);

rule Family2Household {
    from f: Families!Family
    to h: Persons!Household (
        adults <- f.adultMembers
    )
}

-- Worse
rule Family2Household {
    from f: Families!Family
    to h: Persons!Household (
        adults <- f.members->select(m | m.age >= 18 and not m.isRetired)
    )
}
```

### Test with Representative Data

Use realistic test models:
- Cover all rule patterns
- Test boundary cases (empty collections, nulls)
- Verify relationships resolve correctly
- Check cardinality constraints

### Compile for Production

Always compile for production use:

```bash
# Development
swift-atl transform Transform.atl --source test.xmi --target out.xmi

# Production
swift-atl compile Transform.atl --optimise
swift-atl transform Transform.asm --source prod.xmi --target out.xmi
```

### Use Libraries for Shared Code

Extract common helpers to libraries:

```atl
-- library: string-utils.atl
module stringUtils;

helper def: capitalise(s: String): String =
    s.substring(0, 1).toUpper() + s.substring(1, s.size());

helper def: normalise(s: String): String =
    s.replaceAll(' ', '_').toLower();
```

Import in transformations:

```bash
swift-atl transform MyTransform.atl \
    --source input.xmi \
    --target output.xmi \
    --library string-utils.atl
```

## Error Handling

### Transformation Errors

Common errors and solutions:

**"No rule matches element"**
- Element type doesn't match any rule
- Guards are too restrictive
- Add catch-all rule or loosen guards

**"Feature not found"**
- Attribute/reference doesn't exist in metamodel
- Typo in feature name
- Validate with metamodels

**"Type mismatch"**
- Binding assigns wrong type
- Collection vs single value
- Check metamodel multiplicities

**"Circular dependency"**
- Rules reference each other's outputs
- Break cycle with lazy rules
- Restructure transformation

### Debugging Strategies

**Use debug mode liberally:**

```bash
swift-atl transform Transform.atl \
    --source input.xmi \
    --target output.xmi \
    --mode debug --verbose 2>&1 | tee debug.log
```

**Validate intermediate steps:**

Create smaller transformations that produce intermediate models,
validate each step.

**Simplify and test:**

Comment out rules, test with minimal transformations, add
complexity incrementally.

## Integration Patterns

### Pre-transformation Validation

```bash
#!/bin/bash
echo "Validating input..."
swift-ecore validate input.xmi --metamodel Source.ecore --strict

if [ $? -eq 0 ]; then
    echo "Transforming..."
    swift-atl transform Transform.atl \
        --source input.xmi --target output.xmi
else
    echo "Input validation failed"
    exit 1
fi
```

### Transformation Chains

```bash
#!/bin/bash
# Stage 1: UML to Database Schema
swift-atl transform UML2Schema.atl \
    --source design.xmi --target schema.xmi

# Validate intermediate
swift-ecore validate schema.xmi --metamodel Schema.ecore

# Stage 2: Schema to SQL DDL
swift-atl transform Schema2DDL.atl \
    --source schema.xmi --target ddl.xmi
```

### Post-transformation Code Generation

```bash
#!/bin/bash
# Transform model
swift-atl transform Process.atl \
    --source input.xmi --target output.xmi

# Generate code from result
swift-mtl generate CodeGen.mtl \
    --model output.xmi --output generated/
```

## Next Steps

- <doc:GettingStarted> - Practical examples
- **swift-ecore** - Model validation
- **swift-mtl** - Code generation from models

## See Also

- [Eclipse ATL (Atlas Transformation Language)](https://eclipse.dev/atl/)
- [OMG QVT (Query/View/Transformation)](https://www.omg.org/spec/QVT/)
- [OMG OCL (Object Constraint Language)](https://www.omg.org/spec/OCL/)
