# Complex Navigation Patterns - Multi-hop Reference Traversal
# AQL supports sophisticated navigation through object graphs

# Conceptual multi-hop patterns (library domain examples):
# library.categories->collect(c | c.books)->flatten()->collect(b | b.authors)->flatten()->asSet()
# author.books->collect(b | b.authors)->flatten()->select(a | a <> author)->asSet()

# Single-hop navigation through references
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->collect(p | p.name)"

# Output: ['Dashboard', 'TaskList', 'Projects', 'Settings', ...]

# Multi-hop navigation through nested references
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->collect(p | p.components)->flatten()->collect(c | c.name)"

# Output: ['MainNav', 'TaskTable', 'ProjectGrid', 'SettingsForm', ...]

# Navigation with intermediate collection flattening
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->collect(p | p.components)->flatten()->select(c | c.oclIsKindOf(Form))->collect(f | f.name)"

# Output: ['TaskForm', 'ProjectForm', 'SettingsForm']

# Complex multi-level navigation through entities
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.entities->collect(e | e.relationships)->flatten()->collect(r | r.targetEntity.name)->asSet()"

# Output: Set{'User', 'Project', 'Task', 'Category'}

# Navigation with filtering at each level
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages
    ->select(p | p.requiresAuth)
    ->collect(p | p.components)
    ->flatten()
    ->select(c | c.oclIsKindOf(DataTable))
    ->collect(t | t.dataSource.name)"

# Output: ['Task', 'Project', 'User']

# Circular navigation - finding related objects
swift-aql evaluate --model webapp-data.xmi \
  --expression "let task = webapp.entities->select(e | e.name = 'Task')->first() in
    task.relationships
      ->collect(r | r.targetEntity)
      ->collect(e | e.relationships)
      ->flatten()
      ->select(r | r.targetEntity = task)
      ->collect(r | r.name)"

# Output: ['tasks', 'assignedTasks', 'relatedTasks']

# Navigation through opposite references
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages->collect(p | p.linkedPages)->flatten()->asSet()->collect(p | p.name)"

# Output: Set{'Dashboard', 'TaskList', 'Projects', 'Help', 'About'}

# Deep navigation for connected components analysis
swift-aql evaluate --model webapp-data.xmi \
  --expression "let forms = webapp.pages->collect(p | p.components)->flatten()->select(c | c.oclIsKindOf(Form)) in
    forms->collect(f | f.fields)->flatten()->collect(fld | fld.boundAttribute)->select(a | a <> null)->asSet()->size()"

# Output: 27

# Navigation with intermediate transformations
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.entities
    ->collect(e | Tuple{
      entity = e.name,
      referencedBy = webapp.entities
        ->collect(other | other.relationships)
        ->flatten()
        ->select(r | r.targetEntity = e)
        ->collect(r | r.eContainer().oclAsType(Entity).name)
    })"

# Output: [
#   Tuple{entity='User', referencedBy=['Task', 'Project', 'Comment']},
#   Tuple{entity='Task', referencedBy=['User', 'Project']},
#   ...
# ]

# Navigation through collections of references
swift-aql evaluate --model webapp-data.xmi \
  --expression "webapp.pages
    ->select(p | p.components->select(c | c.oclIsKindOf(Navigation))->notEmpty())
    ->collect(p | p.components)
    ->flatten()
    ->select(c | c.oclIsKindOf(Navigation))
    ->collect(n | n.oclAsType(Navigation).items)
    ->flatten()
    ->collect(i | i.targetPage)
    ->select(p | p <> null)
    ->asSet()
    ->collect(p | p.name)"

# Output: Set{'Dashboard', 'TaskList', 'Projects', 'Settings', 'Profile'}

# Complex navigation for dependency analysis
swift-aql evaluate --model webapp-data.xmi \
  --expression "let allForms = webapp.pages->collect(p | p.components)->flatten()->select(c | c.oclIsKindOf(Form)) in
    webapp.entities->collect(e | Tuple{
      entity = e.name,
      formCount = allForms->select(f | f.oclAsType(Form).boundEntity = e)->size(),
      fieldBindings = e.attributes->collect(a |
        allForms->collect(f | f.oclAsType(Form).fields)->flatten()->select(fld | fld.boundAttribute = a)->size()
      )->sum()
    })"

# Output: [
#   Tuple{entity='Task', formCount=2, fieldBindings=14},
#   Tuple{entity='Project', formCount=1, fieldBindings=8},
#   ...
# ]

# Navigation patterns are composable and can be arbitrarily deep
# Use asSet() to eliminate duplicates when navigating bidirectional relationships
