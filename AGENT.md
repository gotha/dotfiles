# Working in this repo

## Comments

Short and sparse. A one-line change gets at most a one-line comment, and
usually none.

Comment only what the code cannot say: a surprising ordering, a value that
looks arbitrary but is not, a workaround for a bug elsewhere. Never restate
what the next line already says, never explain a stock NixOS option, never
list the alternatives you rejected.

The reasoning, the measurements and the risks belong in the commit message,
where they are read once by someone asking "why is this here" - not in the
file, where they are read every time by someone trying to see the code.

If the comment is longer than the code it sits above, delete the comment.
