# Navigation Expression Output Examples
# This script demonstrates running MTL templates with navigation expressions

# Run the property access template
swift-mtl generate \
  --template PropertyAccess.mtl \
  --model webapp-model.xmi \
  --metamodel WebApp.ecore \
  --output ./generated

echo "Generated: property-access.txt"

# Run the navigation template
swift-mtl generate \
  --template NavigationTemplate.mtl \
  --model webapp-model.xmi \
  --metamodel WebApp.ecore \
  --output ./generated

echo "Generated: navigation-demo.txt"

# Run the safe navigation template
swift-mtl generate \
  --template SafeNavigation.mtl \
  --model webapp-model.xmi \
  --metamodel WebApp.ecore \
  --output ./generated

echo "Generated: safe-navigation.txt"

# Example output from navigation-demo.txt:
# -----------------------------------------
# Model Navigation with AQL Expressions
# =====================================
#
# Application: TaskManager
#
# Pages in application:
# - Dashboard (/)
# - TaskList (/tasks)
# - Projects (/projects)
# - NewProject (/projects/new)
# - Profile (/profile)
# - Login (/login)
# - Register (/register)
#
# Entity relationships:
# User:
#   - tasks -> Task (oneToMany)
#   - projects -> Project (manyToMany)
#
# Task:
#   - assignee -> User (manyToOne)
#   - project -> Project (manyToOne)
#   - comments -> Comment (oneToMany)
# -----------------------------------------

# View all generated navigation outputs
echo ""
echo "=== Property Access Output ==="
cat ./generated/property-access.txt | head -30

echo ""
echo "=== Navigation Demo Output ==="
cat ./generated/navigation-demo.txt | head -30

echo ""
echo "=== Safe Navigation Output ==="
cat ./generated/safe-navigation.txt | head -30
