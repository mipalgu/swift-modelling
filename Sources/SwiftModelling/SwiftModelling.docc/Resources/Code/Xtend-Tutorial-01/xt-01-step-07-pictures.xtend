import shapes.Circle
import shapes.Drawing
import shapes.Rectangle
import shapes.Shape
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess

class Pictures {
    def doGenerate(Resource resource, IFileSystemAccess fsa) {
        for (drawing : resource.contents.filter(Drawing)) {
            fsa.generateFile(drawing.name + '.svg', drawing.svg)
        }
    }

    def svg(Drawing drawing) '''
        <svg xmlns="http://www.w3.org/2000/svg" width="«drawing.width»" height="«drawing.height»">
          «FOR shape : drawing.shapes»
            «shape.element»
          «ENDFOR»
        </svg>
    '''

    def dispatch element(Circle c) '''
        <circle id="«c.name»" cx="«c.x»" cy="«c.y»" r="«c.radius»"«c.paint»/>
    '''

    def dispatch element(Rectangle r) '''
        <rect id="«r.name»" x="«r.x»" y="«r.y»" width="«r.width»" height="«r.height»"«r.paint»/>
    '''

    def paint(Shape s) '''«IF s.colour !== null» fill="«s.colour»"«ELSE» fill="none" stroke="black"«ENDIF»'''
}
