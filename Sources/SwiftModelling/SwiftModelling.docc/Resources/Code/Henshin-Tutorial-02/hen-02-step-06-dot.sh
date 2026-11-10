# Look at the Graphviz graph of the state space
cat payments.dot

# Output:
# digraph "statespace" {
#   node [shape=circle];
#   s0 [label="0", shape=doublecircle, style="bold"];
#   s1 [label="1"];
#   s2 [label="2", style="bold"];
#   s3 [label="3"];
#   s0 -> s1 [label="payOne"];
#   s0 -> s2 [label="payOne"];
#   s1 -> s3 [label="payOne"];
#   s1 -> s0 [label="payOne"];
#   s2 -> s0 [label="payOne"];
#   s3 -> s1 [label="payOne"];
# }
