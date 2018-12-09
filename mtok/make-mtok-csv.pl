#!perl
# make-mtok-csv.pl: make the mtok.csv describing the tokenizer
# Copyright (c) 2018 Chris White

use 5.016;
use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper;

use Data::DFA qw(:all);
use List::Util qw(max);
use List::MoreUtils qw(first_index zip);
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

# Helper routines {{{2
sub _e($) { goto &element; }     # for convenience
sub _seq { goto &sequence; }  # ditto
sub _elems { return map { _e $_ } split //, shift; }
sub _lit { return sequence(_elems @_); }
# }}}2

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
print STDERR "Tokens:\n", Dumper(\%tokens), "\n";

# }}}1
# Make the DFA {{{1

# TODO figure out how to label these or otherwise automatically generate
# the E_* constants in mtok.nas.  Maybe make an FSM::Simple and use it generate
# Graphviz for a diagram?  Or cycle-break and topo-sort?
# Actually, the example graphviz code in the perldoc for FSM::Simple
# looks simple (!) - I could probably generate it by hand.

# CAUTION: successive runs may produce a different ordering of states :( .
my $dfa = fromExpr(choice(map { $$_[2] } values %tokens));

# Debug output
$dfa->print('DFA', 2);
print STDERR Dumper($dfa), "\n";

# }}}1
# Build the output table {{{1
my @rows;   # [ NFA state, DFA state, type ("accept" or blank), then the
            #   transitions for each input char class ]
push @rows, [Dumper($dfa)];     # useful for debugging

# First, the E_* emit constants
my %emits = compute_emits(
    \%tokens,
    $dfa,
    5       # arbitrary max depth that is large enough to catch everything
);
push @rows, ['EMIT', $_, $emits{$_}] for sort { $a <=> $b } keys %emits;

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
# === Helpers ==============================================================
# Generate the emit labels {{{1

# Compute the EMIT entries.  Takes the tokens and the DFA; returns a hash
# of state => E_* (string).
sub compute_emits {
    my $hrTokens = shift or croak 'Need tokens';
    my $dfa = shift or croak 'Need DFA';
    my $max_depth = shift or croak 'Need max depth';

    print STDERR "Computing emits with max depth $max_depth\n";
    return _dfs($hrTokens, $dfa, $max_depth, '0', '');
} #compute_emits()

sub _dfs {
    my $hrTokens = shift or croak 'Need tokens';
    my $dfa = shift or croak 'Need DFA';
    my $depth_left = shift;     # note that falsy 0 is valid!j
    croak 'Need depth left' unless defined $depth_left;
    my $state = shift;  # note that falsy state '0' is valid!
    croak 'Need current state' unless defined $state;
    my $so_far = shift; # note that falsy '' is valid
    croak 'Need string of transitions so far' unless defined $so_far;

    my @retval;
    my $indent = ' ' x (2*length($so_far));

    my $lrState = $$dfa{$state} or die "No state $state in DFA";
    my (undef, undef, $transitions, $final) = @$lrState;
    print STDERR "$indent> Trying token << $so_far >> in " .
        ($final ? 'accepting ' : '') . "state $state\n";

    # Is this state one that should emit?
    if($final) {
        keys %$hrTokens;    # Reset the each() iterator
        while( my ($token_friendly_name, $lrToken) = each(%$hrTokens)) {
            print STDERR "$indent  Checking regex $$lrToken[0] for $token_friendly_name\n";
            if($so_far =~ $$lrToken[0]) {
                @retval = ($state, $$lrToken[1]);
                print STDERR "$indent> accepting state for $token_friendly_name: ",
                    join(', ', @retval), "\n";
                last;
            }
        }
    }

    if($depth_left) {
        # Follow the edges
        my @outgoing_symbols = keys %$transitions;
        for my $outgoing_sym (@outgoing_symbols) {
            my $next_state = $dfa->transitionOnSymbol($state, $outgoing_sym);
            print STDERR "$indent> trying $state --<< $outgoing_sym >>--> $next_state\n";
            push @retval, _dfs($hrTokens, $dfa, $depth_left-1, $next_state,
                                $so_far . $outgoing_sym);
        }
    }

    return @retval;
} #_dfs()

# }}}1
# vi: set fdm=marker fo-=ro:
