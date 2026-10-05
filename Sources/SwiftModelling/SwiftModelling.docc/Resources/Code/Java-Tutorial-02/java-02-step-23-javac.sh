mkdir -p classes
javac -cp "$EMF_RUNTIME_CLASSPATH" -d classes $(find src -name '*.java')
