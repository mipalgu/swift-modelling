# Run the Organisation2Dot query
swift-atl query organisation2dot.atl \
  --source sample-company.xmi \
  --output-directory charts

# The query writes charts/organisation.dot and prints its value:
# true

# Render the chart with Graphviz, if it is installed
dot -Tsvg charts/organisation.dot -o charts/organisation.svg
