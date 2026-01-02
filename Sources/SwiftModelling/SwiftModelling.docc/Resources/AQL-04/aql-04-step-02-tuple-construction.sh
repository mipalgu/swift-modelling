# Tuple Construction - Creating Structured Data Projections
# Tuples allow you to create ad-hoc record structures with named fields

# Basic tuple construction with literal values
swift-aql evaluate --model webapp-data.xmi \
  --expression "Tuple{title='Book Title', pages=350}"

# Output: Tuple{title='Book Title', pages=350}

# Collect with tuples for data reshaping (conceptual example)
# books->collect(b | Tuple{title=b.title, author=b.author.name, rating=b.rating})
# This pattern creates a collection of tuples, projecting specific fields

# Tuple construction from model data
swift-aql evaluate --model webapp-data.xmi \
  --expression "Tuple{
    appName = webapp.name,
    pageCount = webapp.pages->size(),
    entityCount = webapp.entities->size()
  }"

# Output: Tuple{appName='TaskManager', pageCount=7, entityCount=4}

# Using tuples in collect operations for data projection
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->collect(p | Tuple{
    name = p.name,
    route = p.route,
    componentCount = p.components->size(),
    requiresAuth = p.requiresAuth
  })"

# Output: [
#   Tuple{name='Dashboard', route='/', componentCount=3, requiresAuth=false},
#   Tuple{name='TaskList', route='/tasks', componentCount=2, requiresAuth=true},
#   ...
# ]

# Nested tuple construction
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.entities->collect(e | Tuple{
    entity = Tuple{name=e.name, tableName=e.tableName},
    stats = Tuple{
      attributeCount = e.attributes->size(),
      relationshipCount = e.relationships->size()
    }
  })"

# Output: [
#   Tuple{entity=Tuple{name='Task', tableName='tasks'}, stats=Tuple{attributeCount=7, relationshipCount=2}},
#   ...
# ]

# Tuples for data reshaping and reporting
swift-aql evaluate --model webapp-data.xmi \
  --expression "let pages = webapp.pages in
    Tuple{
      totalPages = pages->size(),
      publicPages = pages->select(p | not p.requiresAuth)->size(),
      protectedPages = pages->select(p | p.requiresAuth)->size(),
      averageComponents = pages->collect(p | p.components->size())->sum() / pages->size()
    }"

# Output: Tuple{totalPages=7, publicPages=3, protectedPages=4, averageComponents=2.5}

# Tuples with complex expressions
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.entities->collect(e | Tuple{
    name = e.name,
    primaryKey = e.attributes->select(a | a.isPrimaryKey)->first().name,
    requiredFields = e.attributes->select(a | not a.isNullable)->collect(a | a.name),
    hasRelationships = e.relationships->notEmpty()
  })"

# Output: [
#   Tuple{name='Task', primaryKey='id', requiredFields=['id', 'title', 'status'], hasRelationships=true},
#   ...
# ]

# Tuple field access with dot notation
swift-aql evaluate --model webapp-data.xmi \
  --expression "let summary = Tuple{name=webapp.name, version=webapp.version} in
    summary.name + ' v' + summary.version"

# Output: 'TaskManager v1.0.0'

# Tuples for creating custom view models
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->select(p | p.components->notEmpty())->collect(p |
    Tuple{
      pageInfo = p.name + ' (' + p.route + ')',
      forms = p.components->select(c | c.oclIsKindOf(Form))->size(),
      tables = p.components->select(c | c.oclIsKindOf(DataTable))->size(),
      navigation = p.components->select(c | c.oclIsKindOf(Navigation))->size()
    }
  )"

# Output: [
#   Tuple{pageInfo='Dashboard (/)', forms=0, tables=2, navigation=1},
#   Tuple{pageInfo='TaskList (/tasks)', forms=1, tables=1, navigation=0},
#   ...
# ]

# Tuples are immutable once created
# Fields can be accessed but not modified
