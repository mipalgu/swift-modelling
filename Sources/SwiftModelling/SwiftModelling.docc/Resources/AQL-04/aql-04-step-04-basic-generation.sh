# Basic MTL Generation with AQL Expressions
# This script demonstrates running a basic MTL template

# Run the basic template to generate documentation
swift-mtl generate \
  --template BasicGeneration.mtl \
  --model webapp-model.xmi \
  --metamodel WebApp.ecore \
  --output ./generated

# Output directory structure:
# generated/
#   README.md

# Example generated README.md content:
# -----------------------------------------
# # TaskManager
#
# Version: 1.0.0
# Base URL: https://tasks.example.com
#
# ## Overview
#
# This web application contains:
# - 7 pages
# - 4 data entities
# - 3 stylesheets
#
# ## Pages
#
# - **Dashboard**: `/`
# - **TaskList**: `/tasks`
# - **Projects**: `/projects`
# ...
# -----------------------------------------

# The AQL expressions in the template are evaluated:
# [app.name/] -> TaskManager
# [app.version/] -> 1.0.0
# [app.pages->size()/] -> 7
# [app.entities->size()/] -> 4

# View the generated file
cat ./generated/README.md
