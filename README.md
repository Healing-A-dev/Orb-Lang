# ORB
Introducing Orb! A compiled programming language that is (suprisingly) not a C, Rust, Java, or Go clone. Being built on top of a custom VM and micro Lua transpilers 'Xohe', Orb is a very fast and rather lightweight language.

# HOW TO:
The syntax of Orb is rather similar to languages such as Perl and Julia with some major differences.
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
```
When reassigning variables, the ':=' can simply be '=' since ':=' is used to declare variables, however it is still okay if you choose to use ':=' to reassign variables.
