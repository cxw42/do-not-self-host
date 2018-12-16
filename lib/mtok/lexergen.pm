#!perl
# mtok::lexergen: make the mtok.csv describing the tokenizer
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

use parent 'Exporter';
our @EXPORT = qw(_e _seq _elems _lit);

# Exported helper routines {{{1
sub _e($) { goto &element; }     # for convenience
sub _seq { goto &sequence; }  # ditto
sub _elems { return map { _e $_ } split //, shift; }
sub _lit { return sequence(_elems @_); }
# }}}1

sub main { # {{{1

=head2 main

Make the CSV table for a lexer.  Usage:

    my $lrRows = mtok::lexergen::main(\%tokens)

Returns an arrayref of the data.  See L</write_csv> for writing to a file.

The input hashref is as follows.
The key is a reminder not used
by the program.  The value is an array of: a regex matching the sequence of
symbols; the EMIT constant for that value; and the Data::DFA expression.

=cut

    my $hrTokens = shift or croak('Need token definitions');
    croak 'Need a token hashref' unless ref $hrTokens eq 'HASH';
    my $csv = '';

    print STDERR "Tokens:\n", Dumper($hrTokens), "\n";

    # Make the DFA {{{2

    # TODO figure out how to label these or otherwise automatically generate
    # the E_* constants in mtok.nas.  Maybe make an FSM::Simple and use it generate
    # Graphviz for a diagram?  Or cycle-break and topo-sort?
    # Actually, the example graphviz code in the perldoc for FSM::Simple
    # looks simple (!) - I could probably generate it by hand.

    # CAUTION: successive runs may produce a different ordering of states :( .
    my $dfa = fromExpr(choice(map { $$_[2] } values %$hrTokens));

    # Debug output
    $dfa->print('DFA', 2);
    print STDERR Dumper($dfa), "\n";

    # }}}2
    # Build the output table {{{2
    my @rows;   # [ NFA state, DFA state, type ("accept" or blank), then the
                #   transitions for each input char class ]
    push @rows, [Dumper($dfa)];     # useful for debugging

    # First, the E_* emit constants
    my %emits = _compute_emits(
        $hrTokens,
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

    # }}}2

    return \@rows;
} #main

# }}}1

sub write_csv { # {{{1

=head2 write_csv

Usage:

    mtok::lexergen::write_csv $filename, \@rows;

=cut

    my $filename = shift or croak 'Need a filename';
    my $lrCSV = shift or croak 'Need CSV data';
    croak 'Need a list ref of the CSV data' unless ref $lrCSV eq 'ARRAY';

    my $csv = Text::CSV->new( { binary => 1 } ) or die "Could not create csv instance";
    open my $fh, '>', 'mtok-generated.csv' or die "Could not open file to write";
    $csv->say($fh, $_) for @$lrCSV;
    close $fh;
}

# }}}1
# === Helpers ==============================================================
# Generate the emit labels {{{1

# Compute the EMIT entries.  Takes the tokens and the DFA; returns a hash
# of state => E_* (string).
sub _compute_emits {
    my $hrTokens = shift or croak 'Need tokens';
    my $dfa = shift or croak 'Need DFA';
    my $max_depth = shift or croak 'Need max depth';

    print STDERR "Computing emits with max depth $max_depth\n";
    return _dfs($hrTokens, $dfa, $max_depth, '0', '');
} #_compute_emits()

sub _dfs {
    my $hrTokens = shift or croak 'Need tokens';
    my $dfa = shift or croak 'Need DFA';
    my $depth_left = shift;     # note that falsy 0 is valid!j
    croak 'Need depth left' unless defined $depth_left;
    my $state = shift;  # note that falsy state '0' is valid!
    croak 'Need current state' unless defined $state;
    my $so_far = shift; # note that falsy '' is valid
    croak 'Need string of transitions so far' unless defined $so_far;

    # TODO stop if there are no final (accepting) states left to process

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
