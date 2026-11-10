# Import the module again, turning every sum type into classes
swift-ecore inspect Arith.asdl --asdl-enumerations never

# Output:
# Metamodel: Arith.asdl (ASDL)
# ...
#   Classes: 11 (2 abstract)
#   Enumerations: 0
# ...
#   Abstract class op
#   Class Add extends op
#   Class Sub extends op
#   Class Mul extends op
#   Class Div extends op
#   Class program
