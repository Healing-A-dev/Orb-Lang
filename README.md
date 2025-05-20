# ORB
Introducing Orb! A compiled programming language that is (suprisingly) not a C, Rust, Java, or Go clone. Being built on top of a custom VM 'Xohe', Orb is a very fast and rather lightweight language.

# SYNTAX:
The syntax of Orb is rather similar to languages such as Perl and Julia with some major differences.
___
### Variables:
Creating and assigning variables in Orb is really simple and straight forward given that Orb is dynamically typed. There are also only two types of variables that can be found in Orb. Static variables and global variables. All variables, function, modules, etc are static by default. To make a variable global and able to be used throughout the entire program, simply use the 'global' key word.
```julia
# Declaring a variable is as simple as 'variable := value'
global String := "Bobert"
Number := 900
Array  := []
```
Do note, data can NOT be assigned to a variable that has not been declared ie.
```julia
global String := "Bobert"
Number := 900
Array  := []

String = "Richard"                # No erroes since String was previous declared
Number = "9000"                   # No erroes since Number was previous declared
Array  = ["Hello", "World"]       # No erroes since Array was previous declared

Message = "Hello World"         # Throws an undeclared variable error since 'Message' was no declared and data is trying to get assigned to it

# NOTE: When reassigning variables, the ':=' can simply be '=' since ':=' is used to declare variables, however it is still okay if you choose to use ':=' to reassign variables.
```


### Functions:
Functions are also really straight forward in Orb.
```julia
func add(x, y) {
    ret x + y
}

global func subtract(x, y) {
    ret x - y
}
```
Given the event that you have a function that does not take any arguments, in Orb, you won't even need to use and parenthesis for said function. ie:
```julia
func sayHello {
    put("Hello, World!")
}
```
