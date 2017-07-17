+++
date = "2017-07-18T00:01:06+03:00"
title = "Parsing with leex and yecc"

+++

This post is mostly inspired by the Erlang [master class](https://www.youtube.com/watch?v=gKRyAb7d8lo&list=PLR812eVbehlwEArT3Bv3UfcM9wR3AEZb5) taught by University of Kent. Though with some modifications. The master class is about building a simple calculator program in Erlang, with little information on parsing, which is done by hands there. However there are tools [leex](http://erlang.org/doc/man/leex.html) and [yecc](http://erlang.org/doc/man/yecc.html) in Erlang designed to handle parsing part, and they are far less documented than their counterparts. So this blog post will, I hope, shrink the documentation gap.

In this post I will explain how to use `leex` and `yecc` to build a simple parser of arithmetic expressions. Also, once they are parsed, I will evaluate them using several strategies. In more details we first need to move from this form `1 + 2 * 3` to this one

```erlang
{add, 
    1, 
    {mult, 
        2, 
        3
    }
}
```

which is the tree representation of the first expression. And then we will evaluate the parsed expression to get its result.

#### The lexer

Since parsers operate on tokens and not on a whole string, before feeding an expression to the parser, we need to transform a string to a list of of tokens. First, let's define tokens used in expressions: `number`, `variable`, and arithmetic expression. Variables are used to pass context with bag of values to our evaluator and refer to this values from the expression. Since we a ready to write the lexer, let's look on the `leex` file syntax.

The file consists of three sections:

* Definitions. - they are variables that can be simply reused in the Rules. section
* Rules. - the regular expressions based on which tokens are matched and generated
* Erlang code. - helper functions that may be used in the Rules. section.

For instance number definition is `NUMBER = [0-9]+` and variable definition is `VAR = [A-Za-z][A-Za-z0-9]*`. Below is the full listing of the lexer grammar. It is stored in the file with `.xrl` extension `calculator_lexer.xrl`:

```erlang
Definitions.

NUMBER = [0-9]+
WS = [\s\t]
LB = \n|\r\n|\r
VAR = [A-Za-z][A-Za-z0-9]*

Rules.
{VAR}      : {token, {var, TokenLine, list_to_atom(TokenChars)}}.
{NUMBER}    : {token, {number, TokenLine, list_to_integer(TokenChars)}}.
\+          : {token, {plus, TokenLine}}.
\-          : {token, {minus, TokenLine}}.
\*          : {token, {mult, TokenLine}}.
\/          : {token, {divd, TokenLine}}.
\(          : {token, {lparen, TokenLine}}.
\)          : {token, {rparen, TokenLine}}.
{WS}        : skip_token.
{LB}        : skip_token.

Erlang code.

```
According to the documentation on `leex`, the code from the Rules section must return one of the following:

* `{token, Token}` - the Token will be returned to the caller
* `{end_token, Token}` - returned token is the last token and tokenizing process will stop
* `skip_token` - strings that match this rule are ignored and not returned to the caller
* `{error, ErrorString}` - return the ErrorString

Also `leex` has following predefined variables:

* TokenChars - list of matched characters
* TokenLine - line number 
* TokenLen - length of the match

So now everything is clear. For `var` and `number` rules in the return tuple we return their matched values, which are stored in the TokenChars variable. But instead of returning characters as a token value we transform them to the values we need. I.e. numbers are converted to integer and variable names are converted to atoms. And for the rest of the tokens, which are operators and parenthesis we are not interested in their values, thus we return only corresponding atoms. The only thing that is worth mentioning, that in order to feed tokenizer output to `yecc` generated parser, you must return a tuple of at least 2 elements, where first element is token category, second one is the line number where it was found and the third, which is optional, is the value of the token.

Now you can convert your `.xrl` definition file to the Erlang module and test the lexer. 

```erlang
1> leex:file("calculator_lexer.xrl").
{ok,"./calculator_lexer.erl"}
2> c(calculator_lexer).
{ok,calculator_lexer}
3> calculator_lexer:string("1 + 2 * abc").
{ok,[{number,1,1},
     {plus,1},
     {number,1,2},
     {mult,1},
     {var,1,abc}],
    1}
```


#### The parser

After building the lexer and getting a list of tokens from an expression string, it's time to move on and create a parser. Parser will arrange tokens obtained from the lexer to the expression syntax tree. Later we will process the tree and will get our expression evaluated.

Erlang parser grammar is stored in the file with `*.yrl` extension `calculator_parser.yrl`:

```erlang
Nonterminals
expression term factor.

Terminals
number plus minus mult divd lparen rparen var.

Rootsymbol expression.

expression -> term: '$1'.
expression -> expression plus term: { add, '$1', '$3' }.
expression -> expression minus term: { subtr, '$1', '$3' }.

term -> term mult factor: { mult, '$1', '$3' }.
term -> term divd factor: { divd, '$1', '$3' }.
term -> factor: '$1'.

factor -> number: { number, unwrap('$1') }.
factor -> var: { var, unwrap('$1') }.
factor -> lparen expression rparen: '$2'.

Erlang code.

unwrap({_,_,V}) -> V.
```

The `yecc` definitions file consists of the following sections:

* Header - optional, and it's... a header
* Terminals - elements that are not divided to other elements, these are the tokens we got from the lexer
* Nonterminals - parts of your grammar that can be recursively divided to other either non-terminals or terminals
* Rootsymbol - starting point of your grammar, like start_rule for `ANTLR`
* Rules - your grammar rules, telling the parser how to build a syntax tree from the tokens consumed
* Erlang code. - helper methods

Rules have the following syntax

```erlang
left_part -> right_part : Erlang code
```
where `left_part` is a nonterminal expression, `right_part` is combination of nonterminal or terminal elemnts and `code` is the code associated with the rule.

For instance following rules for `factor` nonterminal tell parser, that when we see  the `{number, _, <value>}` or `{var, _, <value>}` token, it will be parsed either to the `{number, <value>}` node or the `{var, <value>}` correspondingly. We can define multiple rules for the same nonterminal, so this element can match any of rule defined.

```erlang
factor -> number: { number, unwrap('$1') }.
factor -> var: { var, unwrap('$1') }.
```

The `'$1'`, `'$2'`...etc variables represents the contents of the corresponding part of the right-hand side of the rule. In the example above `'$1'` is the consumed `{number, _, <value>}` token. We don't need a line number in our expression tree, thus we convert lexer token to the one suitable for us. `unwrap/1` helper methods extracts the value from a terminal token.

Let's test our parser:

```erlang
1> yecc:file("calculator_parser.yrl").
{ok,"calculator_parser.erl"}
2> c(calculator_parser).
{ok,calculator_parser}
3> {ok, Tokens, _} = calculator_lexer:string("1 + 2 * a").
{ok,[{number,1,1},{plus,1},{number,1,2},{mult,1},{var,1,a}],
    1}
4> calculator_parser:parse(Tokens).
{ok,{add,
        {number,1},
        {mult,
            {number,2},
            {var,a}
        }
    }
}
```

#### Evaluation

Now we have syntax tree and we can use it to evaluate the expression. There are at least 2 ways to do it: by tree traversal and by transforming it into an intermediate language (yes because we can) and running a program to evaluate not the tree, but the intermediate language.

Tree traversal is pretty straightforward, when we see a leaf of the tree, which is either a number or a variable, we return the number or fetch the variable from the passed context and return the fetched value.

```erlang
eval(_Env, {number, N}) -> 
    N;

eval(Env, {var, Name}) ->
    lookup(Name, Env).
```

When a node is met, and it's obviously an operator, we evaluate its left and right parts and apply the operator to the results. I omitted some functions for brevity, but the full source code is on github.

```erlang
eval(Env, {add, L, R}) ->
    eval(Env, L) + eval(Env, R);

eval(Env, {subtr, L, R}) ->
    eval(Env, L) - eval(Env, R);
```

And the result of execution is

```erlang
1> ecalculator:calculate({}, "1 + 2 * 3").
7
```

Part with transforming the tree into intermediate language and feeding it to the state machine is a bit trickier. First let's define a language. We have an empty stack and our tree. The simplest case when there is a single node tree `{number, <N>}`. Then all we need to do is to push the number to the stack and it's our result, so `number` is transformed to the `push` instruction. When the node is `{var, <Name>}`, we should get its value from the context and put it to the stack.  Let's move to more complicated scenarios

```erlang
{add, 
    {number, 1},
    {number, 2}
}
```

For this tree our intermediate language will have following command sequence `[{push, 1}, {push 2}, {add}]` so during its evaluation we will have 2 values on stack when `{add}` operator appears. Generalizing it

```erlang
compile({Operation, L, R}) ->
    compile(L) ++ compile(R) ++ [{Operation}].
```

The whole language for the following expression will look as:

```erlang
1> Tree = ecalculator:parse("1 + 2 * 3").
{add,{number,1},{mult,{number,2},{number,3}}}
2> ecalculator:compile(Tree).
[{push,1},{push,2},{push,3},{mult},{add}]
```

#### Conclusion

In this post we've built a simple lexer and a parser for the small arithmetic expression grammar. Though parsing a real language like Erlang is a way harder comparing to the examples we used in the post, but knowledge how and where to start is still valuable. Using the tools from the post you can easily move from trivial grammar to more complex one. 