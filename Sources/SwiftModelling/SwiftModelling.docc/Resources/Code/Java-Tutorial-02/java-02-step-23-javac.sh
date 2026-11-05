mkdir -p classes
javac -cp "$(cat emf-runtime.classpath)" -d classes $(find src -name '*.java')
