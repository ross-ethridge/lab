### Creating a Class

To create a class in Python, you use the `class` keyword followed by the class name (by convention, class names are written in CamelCase). Here's a simple example of a class:

```python
class Dog:
    # Constructor method to initialize attributes
    def __init__(self, name, age):
        self.name = name  # Instance attribute
        self.age = age    # Instance attribute

    # Method to display information about the dog
    def bark(self):
        print(f"{self.name} says Woof!")

    # Method to get the dog's age
    def get_age(self):
        return self.age
```

### Explanation of the Components

1. **Class Definition**: `class Dog:` defines a new class named `Dog`.

2. **Constructor (`__init__` method)**: This special method is called when you create a new instance of the class. It initializes the object's attributes. The `self` parameter is a reference to the current instance of the class, allowing access to its attributes and methods.

3. **Instance Attributes**: In the constructor, `self.name` and `self.age` are instance attributes that belong to the specific instance of the class. Each instance of `Dog` will have its own `name` and `age`.

4. **Methods**: The methods `bark` and `get_age` are functions defined within the class that operate on the instance's data.

### Why is `self` Declared?

- **Instance Reference**: `self` is not a keyword in Python but a convention. It is the first parameter of instance methods and allows you to refer to the instance of the class. This is necessary because methods need a way to access the instance's attributes and other methods.

- **Distinguishing Between Instance Attributes and Local Variables**: Using `self` helps distinguish between instance variables (which are prefixed with `self.`) and local variables defined within methods.

### Using the Class

Here's how you can create an instance of the `Dog` class and use its methods:

```python
# Creating an instance of Dog
my_dog = Dog("Rex", 5)

# Calling methods on the instance
my_dog.bark()