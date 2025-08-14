# **ORB**
> [!WARNING]
> Orb is a HEAVY W.I.P language and will be broken most of the time until I figure out how to fix things

Introducing Orb! A compiled programming language that is (suprisingly) not a C, Rust, Java, or Go clone.

### About:
Orb is a compiled programming language that runs on a custom VM called XOHE (pronounced Zoe). Orb gets its name from the way Orb is compiled. Everything, and I mean EVERYTHING that called be ran internally is ran internally. The generated executable is simply all that is needed to produced the exact result of the program. No function, loop, or anything of the sort.

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

String = "Richard"                # No erroes since String was previously declared
Number = "9000"                   # No erroes since Number was previously declared
Array  = ["Hello", "World"]       # No erroes since Array was previously declared

Message = "Hello World"         # Throws an undeclared variable error since 'Message' was not previously declared

# NOTE: When reassigning variables, the ':=' can simply be '=' since ':=' is used to declare variables, however it is still okay if you choose to use ':=' to reassign variables.
```


### Functions:
Functions are also really straight forward in Orb.
```julia
func add(x, y) {
    .x + y
}

global func subtract(x, y) {
    .x - y
}
```
Given the event that you have a function that does not take any arguments, in Orb, you won't even need to use and parenthesis for said function. ie:
```julia
func sayHello {
    put("Hello, World!")
}
```

