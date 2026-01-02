# OCL-Style Collection Operations
# AQL supports the full OCL standard library for collection manipulation

# Conceptual examples (library domain):
# books->including(newBook)
# books->excluding(oldBook)
# books->one(b | b.title = '1984')
# books->any(b | b.rating >= 4.8)

# SELECT - Filter elements matching a predicate (covered in previous tutorials)
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->select(p | p.requiresAuth)"

# Output: [Page(TaskList), Page(Projects), Page(Settings), Page(Profile)]

# REJECT - Inverse of select, excludes matching elements
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->reject(p | p.requiresAuth)"

# Output: [Page(Dashboard), Page(About), Page(Help)]

# COLLECT - Transform each element (similar to map)
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.entities->collect(e | e.name + ' (' + e.tableName + ')')"

# Output: ['Task (tasks)', 'Project (projects)', 'User (users)', ...]

# FORALL - Universal quantification (all elements must satisfy predicate)
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.entities->forAll(e | e.name <> null and e.name <> '')"

# Output: true

# Check all pages have valid routes
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->forAll(p | p.route.startsWith('/'))"

# Output: true

# EXISTS - Existential quantification (at least one element satisfies predicate)
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->exists(p | p.name = 'Dashboard')"

# Output: true

# Check if any entity has more than 10 attributes
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.entities->exists(e | e.attributes->size() > 10)"

# Output: false

# ONE - Exactly one element satisfies predicate
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->one(p | p.route = '/')"

# Output: true (only Dashboard has root route)

# ANY - Get an arbitrary element matching predicate
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->any(p | p.requiresAuth)"

# Output: Page(TaskList) [or any other authenticated page]

# INCLUDING - Add an element to a collection
swift-aql evaluate --model webapp-data.xmi \
  --expression "let publicPages = webapp.pages->select(p | not p.requiresAuth) in
    let pageNames = publicPages->collect(p | p.name) in
    pageNames->including('NewPage')"

# Output: ['Dashboard', 'About', 'Help', 'NewPage']

# EXCLUDING - Remove an element from a collection
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.entities->collect(e | e.name)->excluding('User')"

# Output: ['Task', 'Project', 'Comment', 'Category']

# UNION - Combine two collections
swift-aql evaluate --model webapp-data.xmi \
  --expression "let publicPages = webapp.pages->select(p | not p.requiresAuth)->collect(p | p.name) in
    let authPages = webapp.pages->select(p | p.requiresAuth)->collect(p | p.name)->select(n | n.startsWith('T')) in
    publicPages->union(authPages)"

# Output: ['Dashboard', 'About', 'Help', 'TaskList']

# INTERSECTION - Find common elements
swift-aql evaluate --model webapp-data.xmi \
  --expression "let pagesWithForms = webapp.pages->select(p | p.components->exists(c | c.oclIsKindOf(Form)))->collect(p | p.name)->asSet() in
    let authPages = webapp.pages->select(p | p.requiresAuth)->collect(p | p.name)->asSet() in
    pagesWithForms->intersection(authPages)"

# Output: Set{'TaskList', 'Projects', 'Settings'}

# PRODUCT - Cartesian product of collections
swift-aql evaluate --model webapp-data.xmi \
  --expression "let fieldTypes = Sequence{'text', 'email', 'password'} in
    let required = Sequence{true, false} in
    fieldTypes->product(required)->collect(t |
      Tuple{type=t.first(), required=t.second()}
    )"

# Output: [Tuple{type='text', required=true}, Tuple{type='text', required=false}, ...]

# CLOSURE - Transitive closure operation
swift-aql evaluate --model webapp-data.xmi \
  --expression "let dashboard = webapp.pages->select(p | p.name = 'Dashboard')->first() in
    dashboard->closure(p | p.linkedPages)->collect(p | p.name)"

# Output: ['Dashboard', 'TaskList', 'Projects', 'About', 'Help', ...]

# ITERATE - General-purpose accumulator (manual fold/reduce)
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.entities->iterate(e; acc : Integer = 0 |
    acc + e.attributes->size()
  )"

# Output: 42 (total number of attributes across all entities)

# COUNT - Count occurrences of a value
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->collect(p | p.requiresAuth)->count(true)"

# Output: 4

# SORTEDBY - Sort collection by an expression
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.entities->sortedBy(e | e.name)->collect(e | e.name)"

# Output: ['Category', 'Comment', 'Project', 'Task', 'User']

# Complex OCL operation combinations
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.entities
    ->select(e | e.attributes->exists(a | a.isPrimaryKey))
    ->reject(e | e.relationships->isEmpty())
    ->sortedBy(e | e.relationships->size())
    ->collect(e | Tuple{
      name = e.name,
      hasRelationships = true,
      relationshipCount = e.relationships->size()
    })"

# Output: [
#   Tuple{name='Category', hasRelationships=true, relationshipCount=1},
#   Tuple{name='Comment', hasRelationships=true, relationshipCount=2},
#   ...
# ]

# OCL operations are chainable and composable
# They preserve immutability - original collections are never modified
