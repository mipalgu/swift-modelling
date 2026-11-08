# Find the annotations that the Xcore reader added
grep -n "basePackage" Library-xcore.ecore
grep -n -A2 "http://www.eclipse.org/emf/2011/Xcore" Library-xcore.ecore

# Output:
# 4:    <details key="basePackage" value="org.example"/>
# 13:      <eAnnotations source="http://www.eclipse.org/emf/2011/Xcore">
# 14-        <details key="body" value="{&#xA;&#x9;&#x9;copies > 0&#xA;&#x9;}"/>
# 15-      </eAnnotations>
