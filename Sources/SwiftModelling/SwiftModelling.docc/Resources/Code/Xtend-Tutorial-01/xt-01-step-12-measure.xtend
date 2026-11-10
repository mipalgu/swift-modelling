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

    def enlarge(Drawing drawing, int factor) {
        drawing.name = drawing.name + '-large'
        drawing.width = drawing.width * factor
        drawing.height = drawing.height * factor
        drawing.shapes.forEach[
            x = x * factor
            y = y * factor
            grow(factor)
        ]
    }

    def dispatch grow(Circle c, int factor) {
        c.radius = c.radius * factor
    }

    def dispatch grow(Rectangle r, int factor) {
        r.width = r.width * factor
        r.height = r.height * factor
    }
}
