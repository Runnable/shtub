# shtub
Bash command stubbing

[![Build Status](https://travis-ci.org/Runnable/shtub.svg?branch=master)](https://travis-ci.org/Runnable/shtub)

## Overview
shtub is a bash testing utility that allows for the creation of command stubs
in a bash environment. A stub acts as a "faux" command which override the
default behavior of a command and allows the programmer to set specific behaviors
(such as output to `stdout` or `stderr`, return codes, etc.).

## Installation
To install shtub in the current directory, run:
```bash
curl -L https://raw.github.com/runnable/shtub/master/shtub.sh > ./shtub.sh
```

## Example: using `shtub` with `shpec`
```bash
#!/bin/bash
source "./shtub.sh"

# Testing a custom exponential back off function that executes commands
# until they succeed...
describe 'util/backoff'
  # before
    # Create a testing stub action that will fail on the first and second call,
    # then finally succeed on the third call
    stub::errors 'action' 'failed'
    action::on_call 3 true

    # Create a secondary stub action that fails further down the line
    stub::errors 'action2' 'failed'
    action::on_call 5 true

    # Stub the `sleep` command so we can ensure it is being called
    stub 'sleep'
  # end

  it 'should sleep between tries'
    backoff action
    assert sleep::called_twice
  end

  it 'should exponentially back-off on failure'
    # Reset the action and sleep stubs so we can start fresh
    action::reset
    sleep::reset

    # Perform the test
    backoff action
    assert sleep::called_with 2
    backoff action2
    assert sleep::called_with 8
  end

  # after
    # Finally, after done testing restore the stubs to their original state
    action::restore
    sleep::restore
  # end
end
```

## Limitations
The library has two major limitations:

1. You cannot stub internal library functions, variables, and commands
2. You cannot stub bash built-ins

Without these two rules it would be incredibly easy to fork bomb yourself ;).

## API Reference
Stub is used via a series of commands that mutate a given bash environment by
overriding existing commands and adding specialized functions that allow you to
manipulate their stubbed behavior.

There are two types of commands that can be executed when using the library:

- Setup commands: create stubs for commands in the shell environment
- Stub commands: sugar commands that are "attached" to stubs that allow the user
  to mutate their behavior and perform assertions based on various metrics
  (number of times called, which parameters they were called with, etc.)

In this section we will cover each of the commands and provide usage examples.

### Setup Commands
The only commands exposed are used to initialize stubs in the bash environment.
In addition to overriding the default behavior of the command the setup commands
will add a slew of special `::` methods that can then be called to get information
about how a stub was used.

#### stub `<command>`

- `<command>` - Name of the command to stub

```bash
# Stubs the `cat` command
stub 'cat'
```

Creates a basic stub for the given command. The stub will have no effect and
simply return `0`. This method will also set a slew of methods that can be used
to change the default behavior of the stub. See the `::` methods below for more
information.

#### stub::returns `<command>` `<output>`

- `<command>` - Name of the command to stub
- `<output>` - Output the stub should pipe to `stdout` when called

```bash
stub::returns 'cat' 'foobar'
cat 'neat' # Outputs: foobar
```

Creates a stub for the given command that pipes the given output to `stdout`
when the command is executed.

#### stub::errors `<command>` `<output>` `[code=1]`

- `<command>` - Name of the command to stub.
- `<output>` - Output to pipe to `stderr`
- `[code=1]` - Status code the stub should return (defaults to 1)

```bash
stub::errors 'echo' 'cannot echo?'
echo 'hello' # pipes 'cannot echo?' to stderr, returns code 1
stub::errors 'neat' 'not a commmand' 127
neat # pipes 'not a command' to stderr, returns code 127
```

Creates a stub for the given command that pipes the given output to `stderr` and
returns the given status code.

#### stub::exec `<command>` `<exec-command>`

- `<exec-command>` - Command or function to execute when the stub is called

```bash
# Direct command
stub::exec 'curl' 'echo "wowza"'

# Using a function
echo_stub() {
  echo 'hello'
  echo 'world'
  return 1
}
stub::exec 'echo' echo_stub
```

Creates a stub for the given command that executes the given command string
or function when the stub is called.

### Stub Commands
Stub commands are special commands that are automatically added to the bash
environment when creating a stub. They are also known as `::` commands because
each one starts with the name of the stubbed command, followed by two colons,
and then the name of the action to perform. For example:

```bash
# Generate a stub and all special stub commands for `ls`
stub 'ls'

# Now we can use the stub commands
ls::called_once
ls::restore
```

The rest of this section details each of the special `::` commands that are
available to a stub.

#### ::restore
```bash
# Create the stub
stub 'echo'
echo 'Hi there' # Outputs nothing

# Restore the original command
echo::restore
echo 'Hi there' # Works as expected
```

Restores a command to its original state. Effectively removes the stub and all
special `::` commands from the bash environment.

#### ::reset
```bash
stub 'ps'
ps
ps aux # Call count is now 2, last call arguments are now `aux`
ps::reset # Call count is no 0, last call arguments are now empty
```

Resets all internal call counts and argument lists associated with a stub.

#### ::returns `<output>`

- `<output>` - Output to be piped to `stdout` by the command

```bash
stub 'yes'
# `yes` will now print `no way` every time it is called
yes::returns 'no way'
```
Sets a stub to output the given string to `stdout` and return a `0` status code.

#### ::errors `<output>` `[code=1]`

- `<output>` - Output to pipe to `stderr` when the command is run
- `[code=1]` - Optional status code for the stub (defaults to `1`)

```bash
stub 'mkdir'
mkdir::errors 'Refusing to make directories' 69
```

Sets a stub to error by printing the given string to `stderr` and returning the
given status code.


#### ::exec `<exec-command>`
- `<exec-command>` - Command or function to execute when the stub is called

```bash
stub 'pwd'
pwd_stub() {
  echo '/stfu/no/ob'
}
pwd::exec pwd_stub
```

Sets a stub to execute the given command or function when it is called.

#### ::on_call `<call-number>` `<exec-command>`

- `<call-number>` - The number of the call to override
- `<exec-command>` - Command to execute on the given call number

```bash
stub::returns 'ls' 'default'
ls::on_call 2 'echo two'
ls::on_call 4 'echo four'

ls # Prints 'default'
ls # Prints 'two'
ls # Prints 'default'
ls # Prints 'four'
```

Override the default behavior for the stub for the given call number by having
it run the given command instead.

#### ::called_with `<arg1>` `[arg2 ...]`
- `<arg1> [arg2 ...]` - Arguments with which the stub should have been called.

```bash
stub 'cd'
cd /awesome
cd::called_with '/awesome' # Returns 0
cd::called_with '/aewsom3' # Returns 1
```

Asserts that a stub was called with the given arguments the last time it was
executed.

#### ::called `[number=1]`
- `[number=1]` - Number of times to assert that the stub was called (defaults to
  1)

```bash
stub 'grep'
ls -la / | grep 'neat'
grep::called    # Returns 0
grep::called 14 # Returns 1
```

Asserts that a stub was called the given number of times.

#### ::not_called

```bash
stub 'cwd'
cwd
stub 'mc'
mc::not_called  # Return 0
cwd::not_called # Returns 1
```

Asserts that the stub was not called.

#### ::called_once

```bash
stub 'cp'
cp::called_once # Returns 1
cp a.txt b.txt
cp::called_once # Returns 0
cp b.txt c.txt
cp::called_once # Returns 1
```

Asserts that the stub was called exactly once.

#### ::called_twice

```bash
stub 'mv'
mv alpha omega
mv::called_twice # Return 1
mv omega upsilon
mv::called_twice # Return 0
mv upsilon phi
mv::called_twice # Returns 1
```

Asserts that the stub was called exactly twice.

#### ::called_thrice

```bash
stub 'ls'
ls::called_thrice # Returns 1
ls && ls && ls
ls::called_thrice # Returns 0
ls
ls::called_thrice # Return 1
```

Asserts that the stub was called exactly three times.

## License
MIT
