# Write the Company metamodel in the OMG EMOF format
swift-ecore convert Company.ecore Company.emof
cat Company.emof

# Output:
# Conversion completed: Company.emof
# <?xml version="1.0" encoding="UTF-8"?>
# <xmi:XMI xmi:version="2.0" xmlns:xmi="http://www.omg.org/XMI" xmlns:emof="http://schema.omg.org/spec/MOF/2.0/emof.xml">
#   <emof:Package xmi:id="company" name="company" uri="http://www.example.org/company">
#     <xmi:Extension extender="http://www.eclipse.org/emf/2002/Ecore">
#       <nsPrefix>company</nsPrefix>
#     </xmi:Extension>
#     <ownedType xmi:type="emof:Enumeration" xmi:id="company.EmploymentStatus" name="EmploymentStatus">
# ...
#     <ownedType xmi:type="emof:Class" xmi:id="company.Person" name="Person" isAbstract="true">
#       <ownedAttribute xmi:id="company.Person.name" name="name" isOrdered="true">
#         <type xmi:type="emof:PrimitiveType" href="http://schema.omg.org/spec/MOF/2.0/emof.xml#String"/>
#       </ownedAttribute>
# ...
#     <ownedType xmi:type="emof:Class" xmi:id="company.Company" name="Company">
# ...
#       <ownedAttribute xmi:id="company.Company.employees" name="employees" isOrdered="true" lower="0" upper="*" type="company.Person" isComposite="true" opposite="company.Person.employer"/>
#     </ownedType>
#   </emof:Package>
# </xmi:XMI>
