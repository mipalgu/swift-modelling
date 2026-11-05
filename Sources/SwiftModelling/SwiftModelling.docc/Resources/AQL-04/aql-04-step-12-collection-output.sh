# Collection Operations Output Examples
# This script demonstrates running MTL templates with collection operations

# Run the collection loops template
swift-mtl generate \
  --template CollectionIteration.mtl \
  --model webapp-model.xmi \
  --metamodel WebApp.ecore \
  --output ./generated

echo "Generated: collection-loops.txt"

# Run the filtered loops template
swift-mtl generate \
  --template FilteredIteration.mtl \
  --model webapp-model.xmi \
  --metamodel WebApp.ecore \
  --output ./generated

echo "Generated: filtered-loops.txt"

# Run the collect transformation template
swift-mtl generate \
  --template CollectTransform.mtl \
  --model webapp-model.xmi \
  --metamodel WebApp.ecore \
  --output ./generated

echo "Generated: collect-transform.txt"

# View generated output
echo ""
echo "=== Collection Loops Output ==="
cat ./generated/collection-loops.txt | head -40

echo ""
echo "=== Filtered Loops Output ==="
cat ./generated/filtered-loops.txt | head -40

echo ""
echo "=== Collect Transform Output ==="
cat ./generated/collect-transform.txt | head -40

# Output (excerpt):
# === Collection Loops Output ===
# All pages:
# - Dashboard
# All entities:
# - User
# === Filtered Loops Output ===
# Protected pages only:
# - Dashboard (/) - requires authentication
# - TaskList (/tasks) - requires authentication
# - Projects (/projects) - requires authentication
# - NewProject (/projects/new) - requires authentication
# - Profile (/profile) - requires authentication
# Public pages only:
# - Login (/login) - public access
# - Register (/register) - public access
# === Collect Transform Output ===
# All page names: Dashboard, TaskList, Projects, NewProject, Profile, Login, Register
# All entity table names: users, tasks, projects, comments
# Entity names (uppercase): USER, TASK, PROJECT, COMMENT
