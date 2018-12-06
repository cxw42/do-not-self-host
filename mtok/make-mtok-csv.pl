#!perl
# make-mtok-csv.pl: make the mtok.csv describing the tokenizer
# Copyright (c) 2018 Chris White

use 5.016;
use strict;
use warnings;
use Data::Dumper;

use Data::DFA qw(:all);
use List::MoreUtils qw(first_index);
use Text::CSV;

# Tokenizer language definition {{{1
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
#          Numeric constant
#             ?? (because nfa2dfa reserves ?)
#                Operators that stand for themselves
#                                              Other punctuation that stands
#                                              for itself
#                                                Barewords
#                                                        Whitespace
#                                                           EOF
# SA(A|D)*|D+|QQ|::|<=>|->|<=|>=|=|<>|<|>|:=|-|P|A(A|D)*|W+|E
# === https://cyberzhg.github.io/toolbox/nfa2dfa?regex=U0EoQXxEKSp8RCt8UVF8Ojp8PD0+fC0+fDw9fD49fD09fDw+fDx8Pnw9fC18UHxBKEF8RCkqfFcr

# }}}1
# Make the DFA {{{1
# Helper routines {{{2
sub _e($) { goto &element; }     # for convenience
sub _seq { goto &sequence; }  # ditto
sub _elems { return map { _e $_ } split //, shift; }
sub _lit { return sequence(_elems @_); }
# }}}2

# TODO figure out how to label these or otherwise automatically generate
# the E_* constants in mtok.nas.  Maybe make an FSM::Simple and use it generate
# Graphviz for a diagram?  Or cycle-break and topo-sort?
# Actually, the example graphviz code in the perldoc for FSM::Simple
# looks simple (!) - I could probably generate it by hand.

my $dfa = fromExpr(choice(
    # Identifiers
    _seq(_e 'S', _e 'A', zeroOrMore(choice(_e 'A', _e 'D'))),
    # Numeric literals
    oneOrMore(_e 'D'),
    # Punctuation operators
    (map { _lit $_ } qw(QQ :: -> <= >= = <> < > := -)),     # Q = '?'
    # Operator punctuation
    _e 'P',     #choice(_elems '()"[]^*/+,;\\'),
    # Barewords
    _seq(_e 'A', zeroOrMore(choice(_e 'A', _e 'D'))),
    # Whitespace
    oneOrMore(_e 'W'),
    # EOF
    _e 'E'
));

# Debug output
#$dfa->print('DFA', 1);
#print Dumper($dfa), "\n";

# }}}1
# Build the transition table {{{1
my @rows;   # [ NFA state, DFA state, type ("accept" or blank), then the
            #   transitions for each input char class ]
push @rows, [Dumper($dfa)];     # useful for debugging

# TODO make the character-class table

push @rows, ['NFA state', 'DFA state', 'Type'];

my @symbols = $dfa->symbols;
my $nsymbols = $#symbols+1;
push @{ $rows[-1] }, @symbols;

# The following code adapted from Data::DFA::print(), since the docs for
# Data::DFA don't cover the data layout.
for my $superStateName (sort { $a <=> $b } keys %$dfa) {
    my $superState = $$dfa{$superStateName};
    my (undef, $nfaStates, $transitions, $Final) = @$superState;
        # ^ state name seems to be always undef
    my @outgoing_symbols = sort keys %$transitions;
            #  vv No NFA states
    my @row = ('', $superStateName, $Final ? 'accept' : '',
        ('') x $nsymbols);

    # Fill in the transition table
    for my $outgoing_sym (@outgoing_symbols) {
        my $next_state = $dfa->transitionOnSymbol($superStateName, $outgoing_sym);
        my $sym_idx = first_index { $_ eq $outgoing_sym } @symbols;
        $row[3+$sym_idx] = $next_state;     # 3 => NFA state, DFA state, type
    } #foreach $outgoing_sym

    push @rows, \@row;
} #foreach $superStateName

# }}}1
# Write the table to mtok-generated.csv {{{1
my $csv = Text::CSV->new( { binary => 1 } ) or die "Could not create csv instance";
open my $fh, '>', 'mtok-generated.csv' or die "Could not open file to write";
$csv->say($fh, $_) for @rows;
close $fh;

# }}}1
# vi: set fdm=marker fo-=ro:
