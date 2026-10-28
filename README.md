# Le Parserlib2
Parserlib2 (may be renamed in future) is a simple GLL parser (and unparser) with nonstandard view of parsing: every rule is a function that takes state and returns command to parser.  
**Note that quality of my code can be very questionable sometimes. Almost no AI was used in this project, all slop is natural.**
[![Vibe-Scale 0: No AI](https://img.shields.io/badge/Vibe--Scale%200-No%20AI-9467bd)](https://github.com/vibesdk/vibe-scale/blob/main/scale/vibe-0.md)

## Examples
In ./examples/ directory you can find examples of using parserlib2.
- mathexp: Simple subset of mathematical language. REPL included.
- json: JSON grammar for parserlib2.

## API
- `try(ptable, name, text, pos)` - Main parsing function. Tries to parse symbol `name` of grammar `ptable` in text `text` at position `pos`. Returns table with all possible parsing variants and table with statistics. Every variant is a table with resulting data under key `data` and end position under `pos`.
- `stry(ptable, name, cdata, opts)` - Main unparsing function. Tries to unparse symbol `name` of grammar `ptable` with data `cdata` and options `opts`. Returns table with possible unparsing results and table with statistics. They may be indented line buffers (see `appendlines`), simple strings, or something else entirely.
- `appendlines(body, dindent, lines)` - Function used in concatenating indented line buffers. Sadly, my english is too bad to describe how it works.
- `nonterminal(rightside, ending, genesis, decorator)` - Produces pair of parsing and unparsing functions to mimic conventional nonterminal symbol. `rightside` is an array with names of symbols that this functions first requests. Other three arguments are functions, each can be omitted. `ending` takes array with data of these symbols and converts them into data of this nonterminal. `genesis` takes data of this nonterminal and converts it into array of data of these symbols, basically reverse of `ending`. `decorator` takes unparsing results of these symbols and returns unparsing result of this symbol.
- `_nt(this, name, ...)` - helper function, better see grammar sources for usage.
- `terminal(pattern, genesis)` - similar to `nonterminal`, but for terminal symbol. `pattern` is a lua pattern to search in text, `genesis` is a format string for `string.format`. Pattern must contain single capture and is automatically surrounded with `%s`. During unparsing returns indented line buffer.
- `_t(this, name)` - same as `_nt` but for `terminal`

## Inner workings
Omitting details, this is some kind of chimera of GLL, RD and parser combinator.  
**Terminology**:
- Symbol variant - pair of parsing and unparsing function, both return command to function. First one takes symbol state and input text, second one takes state and unparsing options. In context of parser has number.
- Symbol state - object with state of symbol. Has name, reference to parent symbol and reversed linked list with data of all symbols requested for it.
- Parsing variant - possible interpretation of text with grammar. As mentioned above: *variant is a table with resulting data under key `data` and end position under `pos`*.


**Parser structure**:
- Worklist - list of all symbol states to be processed in next iteration.
- Waitlist - 3-level dictionary of lists where symbols that tried to do recursive branching is sleeping. The 3 keys are symbol name, variant number and initial position.
- List of results.

### Basics
As mentioned above, base of parserlib2 is that some function takes symbol state and returns command to parser as first value and arguments as other values. There may be four possible outcomes-commands recognized by parser: error, nonreturn (called disfinish in my code and examples), return and *branch*. Error and nonreturn are simple: parse function throws errors or returns something that parser can't recognize as command (for example, nil value). Parser simply forgets about this symbol state by not adding it to next worklist.  
At the beginning of each iteration, parser creates new empty worklist, and in the end, this new worklist (called `newlist` in code, "next worklist" in README.md) replaces current.

### Return
When function responds with string `"finish"`, some value and new position, parser first tries to resurrect any symbols in corresponding list in waitlist, then, based on whether state's parent is nil, adds new parsing variant into list of results or clones parent, adding new node into linked list and updating position, and puts clone into next worklist.

### Branch
When function responds with string `"branch"` and symbol name, parser tries to add every symbol variant present for that name as symbol state into next worklist. If new symbol state's name, variant number and initial position is equal to these of one of processed state's ancestors, processed state is put into list in waitlist. Otherwise, new state is added into the next worklist.

## Problems
As a very rough prototype that i initially developed for myself, parserlib2 has two significant problems: code quality and documentation availability (and quality).  
There may be bugs, issues with performance (since this is a twice-generalized LL parser, lol), maybe issues with ergonomics. Anyway, feel free to modify it to fit your needs and create issues on github.

## History
Originally there was Macula. Macula was good, but, due to my skill issues, primitive config language for computercraft. When i gained some experience and knowledge about parsing, i finally started still-unfinished Macula2. It was much better, with RD parser that is much more powerful than rest of language. Eager to experiment with parsing, i made non-generalized coroutine-based parserlib(without 2). Then, by life circumstances, i had to parse math expressions, so i started parserlib2. In process, i eventually noticed there's some sort of event happening in PLD discord server and this is why you are reading this.