# swift-henshin

Transform models with Henshin graph transformation rules, and analyse the rules.

## Overview

The `swift-henshin` command-line tool applies the rules and units of
[Eclipse Henshin](https://eclipse.dev/henshin/) modules to models, checks
modules, translates the JavaScript of their attribute expressions into AQL,
finds the conflicts and dependencies of rules, explores the states that rules
reach from a model, and writes modules as Henshin Text.

The tool is built on the swift-henshin package
(https://github.com/mipalgu/swift-henshin), a pure Swift implementation of
Henshin's graph transformation semantics for swift-ecore models.

### Features

- **Both module formats**: Henshin documents in XMI (`.henshin`) and Henshin Text documents
  (`.henshin_text`) are read alike
- **Rule application**: units and rules with typed parameters, application conditions,
  multi-rules and every kind of Henshin unit
- **Matching control**: deterministic or seeded random matching, and overrides of the dangling
  condition and of injective matching
- **Validation**: Henshin's well-definedness checks and the checks of its clean-up operation
- **Expressions**: the translation of Henshin's JavaScript expressions into AQL, and the table
  of supported constructs
- **Critical pair analysis**: conflicts and dependencies at four levels of granularity, as text
  or JSON
- **State spaces**: bounded exploration up to isomorphism, with reachability, invariants,
  forbidden patterns and deadlock checks that print the shortest path to a counterexample, and
  Graphviz export

## Commands

### apply

Apply a unit or rule of a module to a model.

```bash
swift-henshin apply <module> <model> --unit <name> [options]
```

**Options:**

- `-u`, `--unit <name>` - The unit or rule to apply (required)
- `--param <name=value>` - A value for a parameter of the unit; repeat once per parameter
- `-o`, `--output <file>` - The file to write the transformed model to, in the format of its
  extension (XMI unless it is `.json` or `.uml`); default: standard output
- `--dry-run` - Apply the unit without writing or printing the model; cannot be combined with
  `--output`
- `--trace` - List every rule application, with its match and parameter values, on standard
  error
- `--nondeterministic` - Choose matches, and the sub-units of independent units, at random
- `--seed <n>` - Match non-deterministically with a seeded random number generator, so that the
  choices are reproducible
- `--iteration-limit <n>` - Stop loop units after this many iterations, with a warning
- `--check-dangling`, `--no-dangling-check` (or `--no-dangling`) - Check the dangling condition
  for every rule, or for none
- `--injective`, `--non-injective` - Match every rule injectively, or let different nodes of a
  rule match the same object
- `-m`, `--metamodel <file.ecore>` - A metamodel to register before the module is read
  (repeatable)
- `--encoding <name>` - The character encoding of a `.henshin_text` module
- `-v`, `--verbose` - Report progress on standard error

**Parameters.** A value is converted to the declared type of its parameter: an integer for
`EInt`, `ELong`, `EShort` or `EByte`, a real number for `EDouble` or `EFloat`, `true` or
`false` for `EBoolean`, and the text as given for `EString`. A parameter whose type is a class
of the metamodel names an object of the model, either by the value of its `name` attribute (or
its first text attribute), as in `--param target=A`, or by its fragment path, as in
`--param target=//@bins.1`. An untyped parameter takes an integer, a real number or a Boolean
value if the text reads as one, and the text otherwise. A parameter that the unit does not
declare, or that does not accept a value (`OUT` and `VAR` parameters), is an error, as is a
value of the wrong type and a required parameter without a value.

**Output.** The model file itself is never changed. With `--output`, the transformed model is
written to that file; without it, the model is printed on standard output in the format in
which it was read. The parameter values that the unit reports (for a rule, every parameter but
its variables; for other units, the output and input-output parameters) are printed as
`name = value` lines: on standard output, or on standard error while the model is printed on
standard output. Objects are printed as their class followed by their label, as in `Bin(A)`.

**Trace.** `--trace` writes one line per rule application, in order, such as
`applied move(source=Bin(A), target=Bin(B), m=0, n=2): created 0, deleted 0`, with the matched
objects in the order of the left-hand side followed by the parameter values.

**Matching.** Matching is deterministic, as in Henshin. The dangling condition, checked by
default, makes a rule inapplicable where deleting its objects would leave a reference
dangling; with `--no-dangling-check`, such references are removed instead, and deleted objects
take their contents with them. Without the matching options, every rule keeps its own
`checkDangling` and `injectiveMatching` settings.

**Exit statuses.** 0 if the unit applied; 2 if it did not, in which case nothing is written;
1 for other errors, such as a missing parameter or an expression that cannot be evaluated,
which leave the model as it was; 64 for an invalid command line.

**Examples:**

```bash
# Add a parcel and write the result
swift-henshin apply depot.henshin depot.xmi -u addParcel \
    --param binName=A --param code=P3 --param weight=4 -o depot-out.xmi

# See which matches a rule takes, without writing anything
swift-henshin apply depot.henshin_text depot.xmi -u move --trace --dry-run

# Delete an object that is still referenced
swift-henshin apply depot.henshin depot.xmi -u removeParcel --param code=P1 \
    --no-dangling-check -o depot-out.json

# Stop a loop unit after ten iterations
swift-henshin apply depot.henshin depot.xmi -u spin --iteration-limit 10 > depot-out.xmi
```

### validate

Check a module without applying it.

```bash
swift-henshin validate <module> [options]
```

**Options:** `-m`, `--metamodel <file.ecore>`, `--encoding <name>` and `-v`, `--verbose`, as
for `apply`; `--verbose` also prints informational findings.

The command reports what the engine would reject or cannot interpret, such as expressions
outside the supported JavaScript subset or nodes of abstract classes that a rule creates;
Henshin's checks of well-definedness, such as two rules with the same signature or a `VAR`
parameter that no left-hand side uses; and, as warnings, what Henshin's clean-up operation
would remove or repair, such as unused parameters, trivial conditions, and imports that no
node uses or that are missing. A `.henshin_text` module also reports its syntax and
translation errors with their positions.

Each finding is printed on standard output with its severity, place and code, followed by a
summary line:

```text
error: lonely.henshin_text: Rule 'lonely' never matches its VAR parameter 'ghost' in its left-hand side [henshin.var-parameter-not-in-lhs]
warning: lonely.henshin_text: Rule 'lonely' declares parameter 'unused' but uses it nowhere [henshin.unused-parameter]
warning: lonely.henshin_text: Rule 'lonely' declares parameter 'ghost' but uses it nowhere [henshin.unused-parameter]
lonely.henshin_text: 1 error(s), 2 warning(s)
```

**Exit statuses.** 0 if the module has no errors (warnings are allowed); 1 if it has errors or
cannot be read; 64 for an invalid command line.

**Examples:**

```bash
swift-henshin validate depot.henshin
swift-henshin validate depot.henshin_text --metamodel Depot.ecore
```

### translate

Translate a JavaScript expression into AQL, or print the translation table.

```bash
swift-henshin translate <expression> [--variables <name,...>] [--verbose]
swift-henshin translate --table
```

**Options:**

- `-e`, `--expression <expression>` - The expression, instead of the argument
- `--variables <name,...>` - The names that the expression may use, which stand for the
  parameters of a rule or unit; separated by commas or with the option repeated
- `--table` - Print the translations of the supported constructs, one per line as JavaScript,
  AQL and a note separated by tabs
- `-v`, `--verbose` - Also print the names that the expression uses and whether it is a
  literal, a lone variable or a query

Henshin writes attribute values, attribute conditions and iteration counts in JavaScript, and
the engine evaluates them as AQL. Every operation is parenthesised, `/` always divides as real
numbers, and string positions are converted to AQL's one-based indexing. A name that is not
declared, and any construct outside the supported subset, is an error that names the reason.

**Exit statuses.** 0 on success; 1 if the expression cannot be translated; 64 for an invalid
command line.

**Examples:**

```bash
swift-henshin translate "n > 0 && s.length < 5" --variables n,s
# ((n > 0) and (s.size() < 5))

swift-henshin translate --table
```

### analyse

Find the conflicts and dependencies of the rules of a module.

```bash
swift-henshin analyse <module> [options]
```

**Options:**

- `--rules <name,...>` - The rules to analyse, separated by commas or with the option repeated
  (default: every rule of the module)
- `--direction <conflict|dependency|both>` - Whether to find conflicts, dependencies or both
  (default: `conflict`)
- `--granularity <binary|atoms|minimal-reasons|critical-pairs>` - How finely to describe the
  interactions, each level including the coarser ones (default: `minimal-reasons`)
- `--essential` - Report only essential critical pairs
- `--no-multiplicities` - Let overlap graphs ignore the multiplicities of the metamodel
- `--format <text|json>` - The format of the report (default: `text`)
- `--check-dangling`, `--no-dangling-check` - Override the dangling condition of every rule
- `-m`, `--metamodel <file.ecore>`, `--encoding <name>`, `-v`, `--verbose` - As for `apply`

Every ordered pair of the chosen rules is analysed, each rule paired with itself too. A
conflict means that applying the first rule may disable the second (`delete-use`,
`produce-forbid`, `change-use`, `change-forbid`); a dependency means that it may enable the
second (`produce-use`, `delete-forbid`, `change-use`, `change-forbid`). The analysis is static
and over-approximates: attribute conditions and non-literal attribute values are not evaluated,
and the notes of a pair say so.

The text report starts each direction with a matrix of the pairs, holding the number of
minimal reasons (or of atoms), `x` for an interaction found at binary granularity and `.` for
none, followed by the details of each interacting pair:

```text
Conflicts:
             | 0 1
addParcel    | . .
removeParcel | . 1
removeParcel conflicts with removeParcel: delete-use
  atoms: 1
    delete-use #6=#6 in 1 minimal reason(s)
  minimal reasons: 1
    delete-use LHS~LHS {#5=#5, #6=#6, #5-parcels->#6=#5-parcels->#6}
```

The JSON report holds the granularity and, for each direction, the rules and every pair with
its kinds, atoms, minimal reasons, critical pairs, truncation and notes.

**Exit statuses.** 0 on success, whether or not rules interact; 1 if the module cannot be read
or a name is not that of a rule; 64 for an invalid command line.

**Examples:**

```bash
swift-henshin analyse depot.henshin
swift-henshin analyse depot.henshin --rules addParcel,removeParcel \
    --direction both --granularity critical-pairs --no-dangling-check --format json
```

### explore

Explore the states that the rules of a module reach from a model, and check properties.

```bash
swift-henshin explore <module> <model> [options]
```

**Options:**

- `--rules <name,...>` - Rules to apply at every match (repeatable)
- `--units <name,...>` - Units to apply as atomic steps (repeatable)
- `--param <unit.name=value>` - A value for a parameter of a rule or unit, typed as for `apply`
  (repeatable)
- `--max-states <n>` - The largest number of states (default: 100000)
- `--max-depth <n>` - The largest number of steps from the initial state
- `--max-objects <n>` - The largest number of objects of an explored state
- `--identity <isomorphism|identity>` - How states are identified (default: `isomorphism`)
- `--reach <aql>` - Check that a state satisfying the AQL expression is reachable (repeatable)
- `--invariant <aql>` - Check that every state satisfies the AQL expression (repeatable)
- `--forbid <rule>` - Check that no state matches the left-hand side of the rule, with its
  application conditions (repeatable)
- `--deadlock` - Check that no state is a deadlock
- `--dot <file.dot>` - Write the state space as a Graphviz graph
- `--workers <n>` - The number of states expanded at once (default: 4)
- `--check-dangling`, `--no-dangling-check`, `--injective`, `--non-injective` - As for `apply`
- `-m`, `--metamodel <file.ecore>`, `--encoding <name>`, `-v`, `--verbose` - As for `apply`

Without `--rules` and `--units`, every active rule of the module is applied; with `--units`
alone, only the units are. A rule's parameters are bound by matching where its left-hand side
determines them, and `--param` supplies the others; a rule or unit is applied once per state
with the values given. The model file is not changed.

With `--identity isomorphism`, models that differ only in the identities and order of their
objects are the same state; with `--identity identity`, states are told apart unless they have
the same objects. A state cut off by a bound stays open, and the state space is then
incomplete. AQL expressions are evaluated with `self` bound to the first root object of each
state's model.

The report starts with a summary and lists each property with its outcome; a witness of
reachability, or a counterexample, follows with the shortest path to it, each step naming the
rule or unit and its match in the model of the state it starts from:

```text
state space: 6 states, 12 transitions, complete
deadlocks: 1
expanded states: 6, applications: 12
deadlock freedom: does not hold
  state 5 after 2 step(s)
    1. 0 -> 2: drain(bin=Bin(A))
    2. 2 -> 5: drain(bin=Bin(A))
```

A property for which no witness or counterexample was found is inconclusive while the state
space is incomplete, and the report says so. The Graphviz graph draws the initial state as a
double circle, open states dashed, deadlocks as boxes, and the states of the printed paths in
bold. While the state space is explored, the elapsed time is shown on standard error if it is a
terminal, and reported every few seconds with `--verbose`; standard output holds only the
report.

**Exit statuses.** 0 if every property holds (or none is given); 2 if a property does not hold;
3 if none fails but an outcome is inconclusive because the state space is incomplete; 1 for
other errors, such as a parameter without a value or an expression that cannot be evaluated;
64 for an invalid command line.

**Examples:**

```bash
# Is the token ring free of deadlocks?
swift-henshin explore depot.henshin depot.xmi --rules move --deadlock

# Several properties and a graph of the state space
swift-henshin explore depot.henshin depot.xmi --rules move,drain \
    --invariant "self.bins->forAll(b | b.tokens >= 0)" --forbid emptyBin \
    --reach "self.bins->forAll(b | b.tokens = 0)" --dot depot.dot

# A unit as an atomic step, with its parameters, to a bounded depth
swift-henshin explore depot.henshin depot.xmi --units restock \
    --param restock.binName=B --param restock.code=P9 --param restock.weight=1 --max-depth 3
```

### convert

Write a module as Henshin Text.

```bash
swift-henshin convert <module> [<output.henshin_text>] [options]
```

**Options:**

- `-o`, `--output <file>` - The Henshin Text file to write, instead of the second argument;
  without either, the document is printed on standard output
- `--force` - Replace the output file if it exists
- `-m`, `--metamodel <file.ecore>`, `--encoding <name>`, `-v`, `--verbose` - As for `apply`

A `.henshin` or `.henshin_text` module is written as a `.henshin_text` document in canonical
form: reading it back gives a module with the same behaviour, and writing that module again
gives the same document. What Henshin Text cannot express, such as positions of edges, and what
the writer changes in order to express a module, is reported on standard error as `warning:`
lines. Modules are written as Henshin Text only: converting into a `.henshin` document is an
error.

**Exit statuses.** 0 on success; 1 if the module cannot be read, the output exists without
`--force` or the conversion is not supported; 64 for an invalid command line.

**Examples:**

```bash
swift-henshin convert depot.henshin depot.henshin_text
swift-henshin convert depot.henshin
```

## Metamodels and Encodings

Rules refer to the classes of a metamodel. `--metamodel` registers a metamodel, in any format
that swift-ecore reads, before the module is read. Without it, a `.henshin` document finds its
metamodels at the locations that it names, and a `.henshin_text` document finds the packages
that `ePackageImport` names among the Ecore documents beside it. Models are read with the same
metamodels, so that their classes are those of the rules; a model is read in the format that
its extension names, or else in the format of its contents.

A `.henshin_text` module is read as UTF-8; a file that is not valid UTF-8 is read as
ISO-8859-1 instead, with a warning on standard error that names the place of the first byte that
is not UTF-8. `--encoding` names the encoding instead, such as `ISO-8859-1` or `windows-1252`.

## Exit Statuses

| Status | Meaning |
| :-- | :-- |
| 0 | Success |
| 1 | The command failed, or `validate` found errors |
| 2 | `apply` could not apply its unit, or a property of `explore` does not hold |
| 3 | `explore` found no violation, but an outcome is inconclusive because the state space is incomplete |
| 64 | Invalid command line |

## See Also

- [Eclipse Henshin](https://eclipse.dev/henshin/)
- [GROOVE](https://groove.cs.utwente.nl/)
- [Eclipse Acceleo Query Language](https://eclipse.dev/acceleo/)
