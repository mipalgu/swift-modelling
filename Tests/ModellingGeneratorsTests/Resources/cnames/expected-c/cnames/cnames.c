//
//  cnames.c
//

#include "cnames/cnames.h"
#include <stdlib.h>
#include <string.h>

// @generated
const char *Mode_literal(Mode value) {
    switch (value) {
    case Mode_and:
        return "and";
    case Mode_default:
        return "default";
    case Mode_int:
        return "int";
    case Mode_NULL:
        return "NULL";
    case Mode_new:
        return "new";
    case Mode_true:
        return "true";
    default:
        return NULL;
    }
}

// @generated
bool Mode_from_literal(const char *literal, Mode *value) {
    if (literal == NULL || value == NULL) {
        return false;
    }
    if (strcmp(literal, "and") == 0) {
        *value = Mode_and;
        return true;
    }
    if (strcmp(literal, "default") == 0) {
        *value = Mode_default;
        return true;
    }
    if (strcmp(literal, "int") == 0) {
        *value = Mode_int;
        return true;
    }
    if (strcmp(literal, "NULL") == 0) {
        *value = Mode_NULL;
        return true;
    }
    if (strcmp(literal, "new") == 0) {
        *value = Mode_new;
        return true;
    }
    if (strcmp(literal, "true") == 0) {
        *value = Mode_true;
        return true;
    }
    return false;
}

// @generated
Vehicle *Vehicle_create(void) {
    Vehicle *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Vehicle_class;
    self->int_ = 0;
    self->register_ = NULL;
    self->union_ = false;
    self->class_ = NULL;
    self->namespace_ = NULL;
    self->new_ = 0;
    self->delete_ = false;
    self->template_ = NULL;
    self->this_ = NULL;
    self->signed_ = 1.5;
    self->NULL_ = NULL;
    self->eObject_ = NULL;
    self->bool_ = true;
    self->default_ = NULL;
    self->size_t_ = 0;
    self->mode = Mode_and;
    self->modes.items = NULL;
    self->modes.count = 0;
    self->modes.capacity = 0;
    self->keywords.items = NULL;
    self->keywords.count = 0;
    self->keywords.capacity = 0;
    self->driver = NULL;
    self->wheels.items = NULL;
    self->wheels.count = 0;
    self->wheels.capacity = 0;
    self->static__ = NULL;
    self->default_ = EObject_duplicateString("say \"hi\"\n\\there");
    if (self->default_ == NULL) {
        Vehicle_destroy(self);
        return NULL;
    }
    return self;
}

// @generated
void Vehicle_destroy(Vehicle *self) {
    if (self == NULL) {
        return;
    }
    free(self->register_);
    free(self->class_);
    free(self->namespace_);
    free(self->template_);
    free(self->this_);
    free(self->NULL_);
    free(self->eObject_);
    free(self->default_);
    Vehicle_clear_modes(self);
    Vehicle_clear_keywords(self);
    Vehicle_clear_wheels(self);
    free(self);
}

// @generated
int32_t Vehicle_get_int(const Vehicle *self) {
    return self->int_;
}

// @generated
void Vehicle_set_int(Vehicle *self, int32_t value) {
    self->int_ = value;
}

// @generated
const char *Vehicle_get_register(const Vehicle *self) {
    return self->register_;
}

// @generated
bool Vehicle_set_register(Vehicle *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->register_);
    self->register_ = copy;
    return true;
}

// @generated
bool Vehicle_get_union(const Vehicle *self) {
    return self->union_;
}

// @generated
void Vehicle_set_union(Vehicle *self, bool value) {
    self->union_ = value;
}

// @generated
const char *Vehicle_get_class(const Vehicle *self) {
    return self->class_;
}

// @generated
bool Vehicle_set_class(Vehicle *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->class_);
    self->class_ = copy;
    return true;
}

// @generated
const char *Vehicle_get_namespace(const Vehicle *self) {
    return self->namespace_;
}

// @generated
bool Vehicle_set_namespace(Vehicle *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->namespace_);
    self->namespace_ = copy;
    return true;
}

// @generated
int32_t Vehicle_get_new(const Vehicle *self) {
    return self->new_;
}

// @generated
void Vehicle_set_new(Vehicle *self, int32_t value) {
    self->new_ = value;
}

// @generated
bool Vehicle_get_delete(const Vehicle *self) {
    return self->delete_;
}

// @generated
void Vehicle_set_delete(Vehicle *self, bool value) {
    self->delete_ = value;
}

// @generated
const char *Vehicle_get_template(const Vehicle *self) {
    return self->template_;
}

// @generated
bool Vehicle_set_template(Vehicle *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->template_);
    self->template_ = copy;
    return true;
}

// @generated
const char *Vehicle_get_this(const Vehicle *self) {
    return self->this_;
}

// @generated
bool Vehicle_set_this(Vehicle *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->this_);
    self->this_ = copy;
    return true;
}

// @generated
double Vehicle_get_signed(const Vehicle *self) {
    return self->signed_;
}

// @generated
void Vehicle_set_signed(Vehicle *self, double value) {
    self->signed_ = value;
}

// @generated
const char *Vehicle_get_NULL(const Vehicle *self) {
    return self->NULL_;
}

// @generated
bool Vehicle_set_NULL(Vehicle *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->NULL_);
    self->NULL_ = copy;
    return true;
}

// @generated
const char *Vehicle_get_eObject(const Vehicle *self) {
    return self->eObject_;
}

// @generated
bool Vehicle_set_eObject(Vehicle *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->eObject_);
    self->eObject_ = copy;
    return true;
}

// @generated
bool Vehicle_get_bool(const Vehicle *self) {
    return self->bool_;
}

// @generated
void Vehicle_set_bool(Vehicle *self, bool value) {
    self->bool_ = value;
}

// @generated
const char *Vehicle_get_default(const Vehicle *self) {
    return self->default_;
}

// @generated
bool Vehicle_set_default(Vehicle *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->default_);
    self->default_ = copy;
    return true;
}

// @generated
int64_t Vehicle_get_size_t(const Vehicle *self) {
    return self->size_t_;
}

// @generated
void Vehicle_set_size_t(Vehicle *self, int64_t value) {
    self->size_t_ = value;
}

// @generated
Mode Vehicle_get_mode(const Vehicle *self) {
    return self->mode;
}

// @generated
void Vehicle_set_mode(Vehicle *self, Mode value) {
    self->mode = value;
}

// @generated
size_t Vehicle_count_modes(const Vehicle *self) {
    return self->modes.count;
}

// @generated
Mode Vehicle_item_modes(const Vehicle *self, size_t index) {
    if (index >= self->modes.count) {
        return (Mode)0;
    }
    return self->modes.items[index];
}

// @generated
bool Vehicle_add_modes(Vehicle *self, Mode value) {
    if (self->modes.count == self->modes.capacity) {
        void *items = EObject_grown(self->modes.items, &self->modes.capacity, sizeof *self->modes.items);
        if (items == NULL) {
            return false;
        }
        self->modes.items = items;
    }
    self->modes.items[self->modes.count++] = value;
    return true;
}

// @generated
bool Vehicle_remove_modes(Vehicle *self, size_t index) {
    if (index >= self->modes.count) {
        return false;
    }
    memmove(&self->modes.items[index], &self->modes.items[index + 1], (self->modes.count - index - 1) * sizeof *self->modes.items);
    self->modes.count--;
    return true;
}

// @generated
void Vehicle_clear_modes(Vehicle *self) {
    free(self->modes.items);
    self->modes.items = NULL;
    self->modes.count = 0;
    self->modes.capacity = 0;
}

// @generated
size_t Vehicle_count_keywords(const Vehicle *self) {
    return self->keywords.count;
}

// @generated
const char *Vehicle_item_keywords(const Vehicle *self, size_t index) {
    if (index >= self->keywords.count) {
        return NULL;
    }
    return self->keywords.items[index];
}

// @generated
bool Vehicle_add_keywords(Vehicle *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    if (self->keywords.count == self->keywords.capacity) {
        void *items = EObject_grown(self->keywords.items, &self->keywords.capacity, sizeof *self->keywords.items);
        if (items == NULL) {
            free(copy);
            return false;
        }
        self->keywords.items = items;
    }
    self->keywords.items[self->keywords.count++] = copy;
    return true;
}

// @generated
bool Vehicle_remove_keywords(Vehicle *self, size_t index) {
    if (index >= self->keywords.count) {
        return false;
    }
    free(self->keywords.items[index]);
    memmove(&self->keywords.items[index], &self->keywords.items[index + 1], (self->keywords.count - index - 1) * sizeof *self->keywords.items);
    self->keywords.count--;
    return true;
}

// @generated
void Vehicle_clear_keywords(Vehicle *self) {
    for (size_t position = 0; position < self->keywords.count; position++) {
        free(self->keywords.items[position]);
    }
    free(self->keywords.items);
    self->keywords.items = NULL;
    self->keywords.count = 0;
    self->keywords.capacity = 0;
}

// @generated
Driver *Vehicle_get_driver(const Vehicle *self) {
    return self->driver;
}

// @generated
void Vehicle_set_driver(Vehicle *self, Driver *value) {
    self->driver = value;
}

// @generated
size_t Vehicle_count_wheels(const Vehicle *self) {
    return self->wheels.count;
}

// @generated
Wheel *Vehicle_item_wheels(const Vehicle *self, size_t index) {
    if (index >= self->wheels.count) {
        return NULL;
    }
    return self->wheels.items[index];
}

// @generated
bool Vehicle_add_wheels(Vehicle *self, Wheel *value) {
    if (self->wheels.count == self->wheels.capacity) {
        void *items = EObject_grown(self->wheels.items, &self->wheels.capacity, sizeof *self->wheels.items);
        if (items == NULL) {
            return false;
        }
        self->wheels.items = items;
    }
    self->wheels.items[self->wheels.count++] = value;
    return true;
}

// @generated
bool Vehicle_remove_wheels(Vehicle *self, size_t index) {
    if (index >= self->wheels.count) {
        return false;
    }
    EObject_destroy((EObject *)self->wheels.items[index]);
    memmove(&self->wheels.items[index], &self->wheels.items[index + 1], (self->wheels.count - index - 1) * sizeof *self->wheels.items);
    self->wheels.count--;
    return true;
}

// @generated
void Vehicle_clear_wheels(Vehicle *self) {
    for (size_t position = 0; position < self->wheels.count; position++) {
        EObject_destroy((EObject *)self->wheels.items[position]);
    }
    free(self->wheels.items);
    self->wheels.items = NULL;
    self->wheels.count = 0;
    self->wheels.capacity = 0;
}

// @generated
static_ *Vehicle_get_static(const Vehicle *self) {
    return self->static__;
}

// @generated
void Vehicle_set_static(Vehicle *self, static_ *value) {
    self->static__ = value;
}

/// @brief Creates an object of the Vehicle class for its description.
// @generated
static EObject *Vehicle_create_object(void) {
    Vehicle *object = Vehicle_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Vehicle class for its description.
// @generated
static void Vehicle_destroy_object(EObject *object) {
    Vehicle_destroy((Vehicle *)object);
}

// @generated
Truck *Truck_create(void) {
    Truck *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Truck_class;
    self->int_ = 0;
    self->register_ = NULL;
    self->union_ = false;
    self->class_ = NULL;
    self->namespace_ = NULL;
    self->new_ = 0;
    self->delete_ = false;
    self->template_ = NULL;
    self->this_ = NULL;
    self->signed_ = 1.5;
    self->NULL_ = NULL;
    self->eObject_ = NULL;
    self->bool_ = true;
    self->default_ = NULL;
    self->size_t_ = 0;
    self->mode = Mode_and;
    self->modes.items = NULL;
    self->modes.count = 0;
    self->modes.capacity = 0;
    self->keywords.items = NULL;
    self->keywords.count = 0;
    self->keywords.capacity = 0;
    self->driver = NULL;
    self->wheels.items = NULL;
    self->wheels.count = 0;
    self->wheels.capacity = 0;
    self->static__ = NULL;
    self->operator_ = 0;
    self->goto_ = NULL;
    self->trailer = NULL;
    self->towedBy = NULL;
    self->default_ = EObject_duplicateString("say \"hi\"\n\\there");
    if (self->default_ == NULL) {
        Truck_destroy(self);
        return NULL;
    }
    self->goto_ = EObject_duplicateString("N/A");
    if (self->goto_ == NULL) {
        Truck_destroy(self);
        return NULL;
    }
    return self;
}

// @generated
void Truck_destroy(Truck *self) {
    if (self == NULL) {
        return;
    }
    free(self->register_);
    free(self->class_);
    free(self->namespace_);
    free(self->template_);
    free(self->this_);
    free(self->NULL_);
    free(self->eObject_);
    free(self->default_);
    Truck_clear_modes(self);
    Truck_clear_keywords(self);
    Truck_clear_wheels(self);
    free(self->goto_);
    free(self);
}

// @generated
int32_t Truck_get_int(const Truck *self) {
    return self->int_;
}

// @generated
void Truck_set_int(Truck *self, int32_t value) {
    self->int_ = value;
}

// @generated
const char *Truck_get_register(const Truck *self) {
    return self->register_;
}

// @generated
bool Truck_set_register(Truck *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->register_);
    self->register_ = copy;
    return true;
}

// @generated
bool Truck_get_union(const Truck *self) {
    return self->union_;
}

// @generated
void Truck_set_union(Truck *self, bool value) {
    self->union_ = value;
}

// @generated
const char *Truck_get_class(const Truck *self) {
    return self->class_;
}

// @generated
bool Truck_set_class(Truck *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->class_);
    self->class_ = copy;
    return true;
}

// @generated
const char *Truck_get_namespace(const Truck *self) {
    return self->namespace_;
}

// @generated
bool Truck_set_namespace(Truck *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->namespace_);
    self->namespace_ = copy;
    return true;
}

// @generated
int32_t Truck_get_new(const Truck *self) {
    return self->new_;
}

// @generated
void Truck_set_new(Truck *self, int32_t value) {
    self->new_ = value;
}

// @generated
bool Truck_get_delete(const Truck *self) {
    return self->delete_;
}

// @generated
void Truck_set_delete(Truck *self, bool value) {
    self->delete_ = value;
}

// @generated
const char *Truck_get_template(const Truck *self) {
    return self->template_;
}

// @generated
bool Truck_set_template(Truck *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->template_);
    self->template_ = copy;
    return true;
}

// @generated
const char *Truck_get_this(const Truck *self) {
    return self->this_;
}

// @generated
bool Truck_set_this(Truck *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->this_);
    self->this_ = copy;
    return true;
}

// @generated
double Truck_get_signed(const Truck *self) {
    return self->signed_;
}

// @generated
void Truck_set_signed(Truck *self, double value) {
    self->signed_ = value;
}

// @generated
const char *Truck_get_NULL(const Truck *self) {
    return self->NULL_;
}

// @generated
bool Truck_set_NULL(Truck *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->NULL_);
    self->NULL_ = copy;
    return true;
}

// @generated
const char *Truck_get_eObject(const Truck *self) {
    return self->eObject_;
}

// @generated
bool Truck_set_eObject(Truck *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->eObject_);
    self->eObject_ = copy;
    return true;
}

// @generated
bool Truck_get_bool(const Truck *self) {
    return self->bool_;
}

// @generated
void Truck_set_bool(Truck *self, bool value) {
    self->bool_ = value;
}

// @generated
const char *Truck_get_default(const Truck *self) {
    return self->default_;
}

// @generated
bool Truck_set_default(Truck *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->default_);
    self->default_ = copy;
    return true;
}

// @generated
int64_t Truck_get_size_t(const Truck *self) {
    return self->size_t_;
}

// @generated
void Truck_set_size_t(Truck *self, int64_t value) {
    self->size_t_ = value;
}

// @generated
Mode Truck_get_mode(const Truck *self) {
    return self->mode;
}

// @generated
void Truck_set_mode(Truck *self, Mode value) {
    self->mode = value;
}

// @generated
size_t Truck_count_modes(const Truck *self) {
    return self->modes.count;
}

// @generated
Mode Truck_item_modes(const Truck *self, size_t index) {
    if (index >= self->modes.count) {
        return (Mode)0;
    }
    return self->modes.items[index];
}

// @generated
bool Truck_add_modes(Truck *self, Mode value) {
    if (self->modes.count == self->modes.capacity) {
        void *items = EObject_grown(self->modes.items, &self->modes.capacity, sizeof *self->modes.items);
        if (items == NULL) {
            return false;
        }
        self->modes.items = items;
    }
    self->modes.items[self->modes.count++] = value;
    return true;
}

// @generated
bool Truck_remove_modes(Truck *self, size_t index) {
    if (index >= self->modes.count) {
        return false;
    }
    memmove(&self->modes.items[index], &self->modes.items[index + 1], (self->modes.count - index - 1) * sizeof *self->modes.items);
    self->modes.count--;
    return true;
}

// @generated
void Truck_clear_modes(Truck *self) {
    free(self->modes.items);
    self->modes.items = NULL;
    self->modes.count = 0;
    self->modes.capacity = 0;
}

// @generated
size_t Truck_count_keywords(const Truck *self) {
    return self->keywords.count;
}

// @generated
const char *Truck_item_keywords(const Truck *self, size_t index) {
    if (index >= self->keywords.count) {
        return NULL;
    }
    return self->keywords.items[index];
}

// @generated
bool Truck_add_keywords(Truck *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    if (self->keywords.count == self->keywords.capacity) {
        void *items = EObject_grown(self->keywords.items, &self->keywords.capacity, sizeof *self->keywords.items);
        if (items == NULL) {
            free(copy);
            return false;
        }
        self->keywords.items = items;
    }
    self->keywords.items[self->keywords.count++] = copy;
    return true;
}

// @generated
bool Truck_remove_keywords(Truck *self, size_t index) {
    if (index >= self->keywords.count) {
        return false;
    }
    free(self->keywords.items[index]);
    memmove(&self->keywords.items[index], &self->keywords.items[index + 1], (self->keywords.count - index - 1) * sizeof *self->keywords.items);
    self->keywords.count--;
    return true;
}

// @generated
void Truck_clear_keywords(Truck *self) {
    for (size_t position = 0; position < self->keywords.count; position++) {
        free(self->keywords.items[position]);
    }
    free(self->keywords.items);
    self->keywords.items = NULL;
    self->keywords.count = 0;
    self->keywords.capacity = 0;
}

// @generated
Driver *Truck_get_driver(const Truck *self) {
    return self->driver;
}

// @generated
void Truck_set_driver(Truck *self, Driver *value) {
    self->driver = value;
}

// @generated
size_t Truck_count_wheels(const Truck *self) {
    return self->wheels.count;
}

// @generated
Wheel *Truck_item_wheels(const Truck *self, size_t index) {
    if (index >= self->wheels.count) {
        return NULL;
    }
    return self->wheels.items[index];
}

// @generated
bool Truck_add_wheels(Truck *self, Wheel *value) {
    if (self->wheels.count == self->wheels.capacity) {
        void *items = EObject_grown(self->wheels.items, &self->wheels.capacity, sizeof *self->wheels.items);
        if (items == NULL) {
            return false;
        }
        self->wheels.items = items;
    }
    self->wheels.items[self->wheels.count++] = value;
    return true;
}

// @generated
bool Truck_remove_wheels(Truck *self, size_t index) {
    if (index >= self->wheels.count) {
        return false;
    }
    EObject_destroy((EObject *)self->wheels.items[index]);
    memmove(&self->wheels.items[index], &self->wheels.items[index + 1], (self->wheels.count - index - 1) * sizeof *self->wheels.items);
    self->wheels.count--;
    return true;
}

// @generated
void Truck_clear_wheels(Truck *self) {
    for (size_t position = 0; position < self->wheels.count; position++) {
        EObject_destroy((EObject *)self->wheels.items[position]);
    }
    free(self->wheels.items);
    self->wheels.items = NULL;
    self->wheels.count = 0;
    self->wheels.capacity = 0;
}

// @generated
static_ *Truck_get_static(const Truck *self) {
    return self->static__;
}

// @generated
void Truck_set_static(Truck *self, static_ *value) {
    self->static__ = value;
}

// @generated
int32_t Truck_get_operator(const Truck *self) {
    return self->operator_;
}

// @generated
void Truck_set_operator(Truck *self, int32_t value) {
    self->operator_ = value;
}

// @generated
const char *Truck_get_goto(const Truck *self) {
    return self->goto_;
}

// @generated
bool Truck_set_goto(Truck *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->goto_);
    self->goto_ = copy;
    return true;
}

// @generated
Truck *Truck_get_trailer(const Truck *self) {
    return self->trailer;
}

// @generated
void Truck_set_trailer(Truck *self, Truck *value) {
    self->trailer = value;
}

// @generated
Truck *Truck_get_towedBy(const Truck *self) {
    return self->towedBy;
}

// @generated
void Truck_set_towedBy(Truck *self, Truck *value) {
    self->towedBy = value;
}

/// @brief Creates an object of the Truck class for its description.
// @generated
static EObject *Truck_create_object(void) {
    Truck *object = Truck_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Truck class for its description.
// @generated
static void Truck_destroy_object(EObject *object) {
    Truck_destroy((Truck *)object);
}

// @generated
Driver *Driver_create(void) {
    Driver *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &Driver_class;
    self->vehicle = NULL;
    return self;
}

// @generated
void Driver_destroy(Driver *self) {
    if (self == NULL) {
        return;
    }
    free(self);
}

// @generated
EObject *Driver_get_vehicle(const Driver *self) {
    return self->vehicle;
}

// @generated
void Driver_set_vehicle(Driver *self, EObject *value) {
    self->vehicle = value;
}

/// @brief Creates an object of the Driver class for its description.
// @generated
static EObject *Driver_create_object(void) {
    Driver *object = Driver_create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the Driver class for its description.
// @generated
static void Driver_destroy_object(EObject *object) {
    Driver_destroy((Driver *)object);
}

// @generated
static_ *static__create(void) {
    static_ *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &static__class;
    self->volatile_ = false;
    return self;
}

// @generated
void static__destroy(static_ *self) {
    if (self == NULL) {
        return;
    }
    free(self);
}

// @generated
bool static__get_volatile(const static_ *self) {
    return self->volatile_;
}

// @generated
void static__set_volatile(static_ *self, bool value) {
    self->volatile_ = value;
}

/// @brief Creates an object of the static class for its description.
// @generated
static EObject *static__create_object(void) {
    static_ *object = static__create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the static class for its description.
// @generated
static void static__destroy_object(EObject *object) {
    static__destroy((static_ *)object);
}

// @generated
FILE_ *FILE__create(void) {
    FILE_ *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &FILE__class;
    return self;
}

// @generated
void FILE__destroy(FILE_ *self) {
    if (self == NULL) {
        return;
    }
    free(self);
}

/// @brief Creates an object of the FILE class for its description.
// @generated
static EObject *FILE__create_object(void) {
    FILE_ *object = FILE__create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the FILE class for its description.
// @generated
static void FILE__destroy_object(EObject *object) {
    FILE__destroy((FILE_ *)object);
}

// @generated
EObject_ *EObject__create(void) {
    EObject_ *self = malloc(sizeof *self);
    if (self == NULL) {
        return NULL;
    }
    self->eObject.eClass = &EObject__class;
    self->eClass_ = NULL;
    return self;
}

// @generated
void EObject__destroy(EObject_ *self) {
    if (self == NULL) {
        return;
    }
    free(self->eClass_);
    free(self);
}

// @generated
const char *EObject__get_eClass(const EObject_ *self) {
    return self->eClass_;
}

// @generated
bool EObject__set_eClass(EObject_ *self, const char *value) {
    char *copy = EObject_duplicateString(value);
    if (copy == NULL && value != NULL) {
        return false;
    }
    free(self->eClass_);
    self->eClass_ = copy;
    return true;
}

/// @brief Creates an object of the EObject class for its description.
// @generated
static EObject *EObject__create_object(void) {
    EObject_ *object = EObject__create();
    return object == NULL ? NULL : &object->eObject;
}

/// @brief Destroys an object of the EObject class for its description.
// @generated
static void EObject__destroy_object(EObject *object) {
    EObject__destroy((EObject_ *)object);
}

/// @brief The features of the Vehicle class.
// @generated
static const EFeatureInfo Vehicle_features[] = {
    { .name = "int", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EInt" },
    { .name = "register", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "union", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EBoolean" },
    { .name = "class", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "namespace", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "new", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EInt" },
    { .name = "delete", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EBoolean" },
    { .name = "template", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "this", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "signed", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EDouble" },
    { .name = "NULL", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "eObject", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "bool", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EBoolean" },
    { .name = "default", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "size_t", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "ELong" },
    { .name = "mode", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "Mode" },
    { .name = "modes", .kind = EFeatureKind_Attribute, .isMany = true, .typeName = "Mode" },
    { .name = "keywords", .kind = EFeatureKind_Attribute, .isMany = true, .typeName = "EString" },
    { .name = "driver", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Driver" },
    { .name = "wheels", .kind = EFeatureKind_Containment, .isMany = true, .typeName = "Wheel" },
    { .name = "static", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "static" },
};

/// @brief The description of the Vehicle class.
// @generated
const EClassInfo Vehicle_class = {
    .name = "Vehicle",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Vehicle_features,
    .featureCount = 21,
    .create = Vehicle_create_object,
    .destroy = Vehicle_destroy_object
};

/// @brief The features of the Truck class.
// @generated
static const EFeatureInfo Truck_features[] = {
    { .name = "int", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EInt" },
    { .name = "register", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "union", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EBoolean" },
    { .name = "class", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "namespace", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "new", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EInt" },
    { .name = "delete", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EBoolean" },
    { .name = "template", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "this", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "signed", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EDouble" },
    { .name = "NULL", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "eObject", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "bool", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EBoolean" },
    { .name = "default", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "size_t", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "ELong" },
    { .name = "mode", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "Mode" },
    { .name = "modes", .kind = EFeatureKind_Attribute, .isMany = true, .typeName = "Mode" },
    { .name = "keywords", .kind = EFeatureKind_Attribute, .isMany = true, .typeName = "EString" },
    { .name = "driver", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Driver" },
    { .name = "wheels", .kind = EFeatureKind_Containment, .isMany = true, .typeName = "Wheel" },
    { .name = "static", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "static" },
    { .name = "operator", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EInt" },
    { .name = "goto", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
    { .name = "trailer", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Truck" },
    { .name = "towedBy", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Truck" },
};

/// @brief The supertypes of the Truck class.
// @generated
static const EClassInfo *const Truck_superTypes[] = { &Vehicle_class };

/// @brief The description of the Truck class.
// @generated
const EClassInfo Truck_class = {
    .name = "Truck",
    .isAbstract = false,
    .superTypes = Truck_superTypes,
    .superTypeCount = 1,
    .features = Truck_features,
    .featureCount = 25,
    .create = Truck_create_object,
    .destroy = Truck_destroy_object
};

/// @brief The features of the Driver class.
// @generated
static const EFeatureInfo Driver_features[] = {
    { .name = "vehicle", .kind = EFeatureKind_Reference, .isMany = false, .typeName = "Vehicle" },
};

/// @brief The description of the Driver class.
// @generated
const EClassInfo Driver_class = {
    .name = "Driver",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = Driver_features,
    .featureCount = 1,
    .create = Driver_create_object,
    .destroy = Driver_destroy_object
};

/// @brief The features of the static class.
// @generated
static const EFeatureInfo static__features[] = {
    { .name = "volatile", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EBoolean" },
};

/// @brief The description of the static class.
// @generated
const EClassInfo static__class = {
    .name = "static",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = static__features,
    .featureCount = 1,
    .create = static__create_object,
    .destroy = static__destroy_object
};

/// @brief The description of the FILE class.
// @generated
const EClassInfo FILE__class = {
    .name = "FILE",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = NULL,
    .featureCount = 0,
    .create = FILE__create_object,
    .destroy = FILE__destroy_object
};

/// @brief The features of the EObject class.
// @generated
static const EFeatureInfo EObject__features[] = {
    { .name = "eClass", .kind = EFeatureKind_Attribute, .isMany = false, .typeName = "EString" },
};

/// @brief The description of the EObject class.
// @generated
const EClassInfo EObject__class = {
    .name = "EObject",
    .isAbstract = false,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = EObject__features,
    .featureCount = 1,
    .create = EObject__create_object,
    .destroy = EObject__destroy_object
};

/// @brief The description of the Shape class.
// @generated
const EClassInfo Shape_class = {
    .name = "Shape",
    .isAbstract = true,
    .superTypes = NULL,
    .superTypeCount = 0,
    .features = NULL,
    .featureCount = 0,
    .create = NULL,
    .destroy = NULL
};

/// @brief The descriptions of the classes of the cnames package.
// @generated
static const EClassInfo *const CnamesPackage_classes[] = {
    &Vehicle_class,
    &Truck_class,
    &Driver_class,
    &static__class,
    &FILE__class,
    &EObject__class,
    &Shape_class,
};

/// @brief The description of the cnames package and its classes.
// @generated
const EPackageInfo CnamesPackage = {
    .name = "cnames",
    .nsURI = "http://swift-modelling.org/test/cnames",
    .nsPrefix = "cn",
    .classes = CnamesPackage_classes,
    .classCount = 7
};

// @generated
EObject *CnamesFactory_create(const EClassInfo *eClass) {
    for (size_t position = 0; position < CnamesPackage.classCount; position++) {
        if (CnamesPackage.classes[position] == eClass) {
            return eClass->create == NULL ? NULL : eClass->create();
        }
    }
    return NULL;
}
