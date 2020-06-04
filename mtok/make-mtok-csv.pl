#!perl
# make-mtok-csv.pl: make the mtok.csv describing the tokenizer
# Copyright (c) 2018 Chris White
#
# TODO? refactor this into a module so I can use the same core for mtok2's
# handling of barewords?

use 5.016;
use strict;
use warnings;

use mtok::lexergen;
use Data::Dumper;
use List::MoreUtils qw(zip);

exit main();

# Tokenizer language definition
sub tokens { # Returns a hashref

    # Try 7: simpler version, without string literals.
    #
    # Each punc char must be exactly one of literal, P, N, S, or A.
    # The literal punc chars are the ones that participate in multiple operators.
    # ASCII punc: !"#$%&'()*+,-./:;<=>?@[\]^_`{|}~
    # Class:      SPSSSS'PPPPP-NP:P<=>QSPPPPANNINN
    #                   ^ not currently in use
    #
    # D ::= [0-9]
    # A ::= [a-zA-Z_]
    # P ::= [()"\[\]^*/+,;\\] <operpunc>
    # N ::= [`~{}.|]
    # S ::= sigil ::= [&$#!@%]
    # Q ::= [?]
    # not currently used => I ::= '|' (pipe char)
    # W ::= [[:space:]]     ; mapped to T_IGNORE
    #
    # Ident
    # |        Numeric constant
    # |        |  ?? (because nfa2dfa reserves '?')
    # |        |  |  Operators that stand for themselves
    # |        |  |  |                             Other punctuation that stands
    # |        |  |  |                             for itself
    # |        |  |  |                             | Barewords
    # |        |  |  |                             | |       Whitespace
    # v        v  v  v                             v v       v  EOF
    # SA(A|D)*|D+|QQ|::|<=>|->|<=|>=|=|<>|<|>|:=|-|P|A(A|D)*|W+|E
    # === https://cyberzhg.github.io/toolbox/min_dfa?regex=U0EoQXxEKSp8RCt8UVF8Ojp8PD0+fC0+fDw9fD49fD18PD58PHw+fDo9fC18UHxBKEF8RCkqfFcrfEU=
    # === https://cyberzhg.github.io/toolbox/regex2nfa?regex=U0EoQXxEKSp8RCt8UVF8Ojp8PD0+fC0+fDw9fD49fD18PD58PHw+fDo9fC18UHxBKEF8RCkqfFcrfEU=

    # Emit names for punctuation operators.  For now, Q = '?'.
    my @punc_ops = qw{ QQ :: <=> -> <= >= = <> < > := - };
    my @puncop_names =
        qw(T_TERN1 T_TERN2 T_SSHIP T_ARROW T_LE T_GE T_EQ T_NE T_LT T_GT T_ASSIGN T_MINUS);
    my %emit_names = zip(@punc_ops, @puncop_names);

    # The code version of the language defn.  The key is a reminder not used
    # by the program.  The value is an array of: a regex matching the sequence of
    # symbols; the EMIT constant for that value; and the Data::DFA expression.
    my %tokens = (
        identifier => [qr{^SA[AD]*$}, T_IDENT => _seq(_e 'S', _e 'A', zeroOrMore(choice(_e 'A', _e 'D')))],
        integer_literal => [qr{^D+$}, T_NUM => oneOrMore(_e 'D')],
        operpunc => [qr{^P$}, EMIT_CHAR => _e 'P'],    #choice(_elems '()"[]^*/+,;\\'),
        bareword => [qr{^A[AD]*$}, T_BAREWORD => _seq(_e 'A', zeroOrMore(choice(_e 'A', _e 'D')))],
        whitespace => [qr{^W+$}, T_IGNORE => oneOrMore(_e 'W')],
        eof => [qr{^E$}, T_EOF => _e 'E'],
        # Punctuation operators
        (map { ("Punc $_", [qr{^\Q$_\E$}, $emit_names{$_}, _lit $_]) } @punc_ops ),
    );

    return \%tokens;
} #tokens

sub main {
    my $hrTokens = tokens;
    print STDERR "Tokens:\n", Dumper($hrTokens), "\n";
    my $lrRows = mtok::lexergen::generate($hrTokens) or die "Couldn't create!";
    mtok::lexergen::write_csv('mtok-generated.csv', $lrRows)
        or die "Couldn't write!";
    return 0;
}

# vi: set fdm=marker fo-=ro:
