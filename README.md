# perplex
Implements interfaces and mixins on top of the object-oriented framework from Éric Tanter's ["Object-Oriented Programming Languages: Application and Interpretation"](https://users.dcc.uchile.cl/~etanter/ooplai/index.html).

# Implementation details

The source code for Perplex lives in `objects.rkt`.

To see examples of Perplex code, explore the `examples/` directory.

## Classes

The core framework for classes is taken from the aforementioned text by Éric Tanter. A brief overview of their implementation and usage is provided here.

### Defining a class

The syntax for defining a class is as follows:

```
(CLASS extends Class
    ([interface iface] ...)
    ([field fname fvalue] ...)
    ([method mname (mparam ...) mbody] ...)))
```

* `CLASS`, `extends`, `interface`, `field`, and `method` are all keywords here.
* `Class` refers to the superclass.
* `iface` refers to an interface.
* `fname` refers to an identifier and `fvalue` refers to any value.
* `mname` and `mparam` refer to identifiers, and `mbody` refers to any expression.

Classes which do not have a superclass should be provided the default super, `Root`.

### Fields and Methods

#### Fields

Fields should be initialized and set using actual values, rather than expressions.

Perplex supports field shadowing, i.e. inheriting classes can reuse field names that are in use by ancestor classes.

#### Field access in methods

To read and write fields within a method, use the following syntax:

 * `(? fname)`: Read a field.
 * `(! fname value)`: Write a value to a field.

#### Method application

The syntax for method application is as follows: `(→ obj mname args ...)`.

This syntax is also valid when used within a method definition. To call a method on the current object, provide `self` for `obj`, like so: `(→ self mname args ...)`.

#### `super()`

Within a method, it is also possible to make a `super()` call to an ancestor classes's method implementation. The syntax for doing so is as follows: `(↑ mname args ...)`.

## Interfaces

A brief overview of the implementation details and usage of interfaces is provided here.

### Defining an interface
The syntax for defining an interface is as follows:

```
(INTERFACE
    ([superinterface super] ...)
    ([method mname] ...))
```

 * `INTERFACE`, `superinterface`, and `method` are all keywords here.
 * `super` refers to an interface that the new interface extends.
 * `mname` refers to an identifier for a method that the new interface requires.

### Implementing an interface

To implement an interface, a class must:
 * Declare the interface in its definition
 * Provide method definitions for all methods required by the interface and its superinterfaces

Note that it is valid for a class to inherit a method definition from a superclass and thereby fulfill a method requirement for an interface. However, it is not valid for a class to declare an interface that will only later be completely implemented by an inheriting class (i.e. abstract classes are not supported).

### Types

Along with interfaces, Perplex introduces the concept of type. That is, an object can be treated as a member of any of its classes, or any of its implementing interfaces.

#### Object instantiation with types

The syntax for instantiating an object is as follows:

```
(new (Type Class))
```

`Class` refers to the concrete type of the object, while `Type` can refer to any valid type of `Class`. That is, the `Class` itself, or any of its superinterfaces or superclasses.

Note that, as expected, an interface cannot be provided in the place of `Class`.

#### Type casting

Objects carry around their current type. An object can be safely cast up to any valid type, based on its current type. The syntax for doing so is as follows:

```
(cast-up Type obj)
```

Casting is particularly important when writing methods that expect an object of a certain type. Because Perplex borrows Racket's weak type checking system, methods should manually "cast-up" object arguments to the desired type before using them.

## Mixins

### Defining mixins

The syntax for defining a mixin is as follows:

```
(MIXIN requires in-iface
       exports out-iface
       ([field fname fvalue] ...)
       ([method mname (mparam ...) mbody] ...))
```

* `MIXIN`, `requires`, `exports`, `field`, and `method` are all keywords here.
* `in-iface` refers to the required interface which the parameterizing superclass must implement.
* `out-iface` refers to the interface which the newly-created class will implement.
* Fields and methods follow the same syntax from class definition.

### Using mixins

`MIXIN` generates a function which takes a parameterizing superclass and returns a new class with the given superclass, fields and methods, and which implements `out-iface`.

Thus, to use a mixin, one need simply to apply the mixin to a superclass, as follows: `(mixin superclass)`.

#### Mixins and super()

When forwarding method calls to the superclass using `↑`, method definitions in a mixin can only forward methods which are declared in the required `in-iface`.

Specifically, this means that a mixin cannot make any assumptions about the functions that might be inherited from the yet-unknown superclass.

#### Method Application

Just as the superclass's non-`in-iface` methods are considered not visible to the mixin-generated class, so are the mixin-generated class's non-`in-iface` methods considered distinct from any overlapping method definitions in the superclass.

This implies that a class can have multiple distinct definitions for a given method. When this happens, the mixin *hides*, rather than *overrides*, the superclass's method definition.

As a result, method application has been altered to occur on the lowest class whose method definition is connected, either through implicit inheritance or explicit redefinition, to the current type of the given object.