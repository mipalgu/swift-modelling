import shapes.Circle
import shapes.Drawing
import shapes.Rectangle

class Measure {
    def describe(Drawing drawing) {
        drawing.shapes.map[summary].join('; ')
    }

    def dispatch summary(Circle c) {
        c.name + ' is a circle of radius ' + c.radius
    }

    def dispatch summary(Rectangle r) {
        r.name + ' is a ' + r.width + ' by ' + r.height + ' rectangle'
    }

    def dispatch area(Circle c) {
        c.radius * c.radius * 314 / 100
    }

    def dispatch area(Rectangle r) {
        r.width * r.height
    }

    def largerThan(Drawing drawing, int minimum) {
        drawing.shapes.filter[area > minimum].map[name].toList
    }

    def total(Drawing drawing) {
        drawing.shapes.map[area].reduce[a, b | a + b]
    }
}
