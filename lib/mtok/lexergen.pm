#!perl
# mtok::lexergen: make the mtok.csv describing the tokenizer
# Copyright (c) 2018 Chris White

package mtok::lexergen;

use 5.016;
use strict;
use warnings;
use Carp qw(croak);
use Data::Dumper;

use Data::DFA qw(:all);
use Data::NFA;
use List::Util qw(max);
use List::MoreUtils qw(first_index);
use Text::CSV;

use parent 'Exporter';
use Import::Into;
our @EXPORT = qw(_e _seq _elems _lit);
our @EXPORT_OK = qw(generate write_csv);

# Docs {{{1

=head1 NAME

mtok::lexergen - Make a lexer table

=head1 EXPORTS

=cut

# }}}1
# Exported helper routines {{{1
sub _e($) { goto &element; }     # for convenience
sub _seq { goto &sequence; }  # ditto
sub _elems { return map { _e $_ } split //, shift; }
sub _lit { return sequence(_elems @_); }
# }}}1

# Tweaked from Data::DFA {{{1
# I need "duplicate" states to stay separate, since they are associated
# with different tokens.

sub fromNfaMy($)                                                                  #P Create a DFA parser from an NFA.
 {my ($nfa) = @_;                                                               # Nfa

  my $dfa       = Data::DFA::newDFA;                                                       # A DFA is a hash of states

  my @nfaStates = (0, $nfa->statesReachableViaJumps(0)->@*);                    # Nfa states reachable from the start state
  my $initialSuperState = join ' ', sort @nfaStates;                            # Initial super state

  $$dfa{$initialSuperState} = Data::DFA::newState(                                         # Start state
    state       => $initialSuperState,                                          # Name of the state - the join of the NFA keys
    nfaStates   => {map{$_=>1} @nfaStates},                                     # Hash whose keys are the NFA states that contributed to this super state
    final       => Data::DFA::finalState($nfa, {map {$_=>1} @nfaStates}),                  # Whether this state is final
   );

  $dfa->superStates($initialSuperState, $nfa);                                  # Create DFA superstates from states reachable from the start state

  my $r = $dfa->renumberDfa->removeUnreachableStates;   # Remove states not reachable from the start state *** but KEEP "duplicate" states

  $r
 }

sub fromExprMy(@)                                                                 #S Create a DFA parser from a regular B<@expression>.
 {my (@expression) = @_;                                                        # Regular expression
  fromNfaMy(Data::NFA::fromExpr(@expression))
 }

# }}}1
sub generate { # {{{1

=head2 generate

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
    my $dfa = fromExprMy(choice(map { $$_[2] } values %$hrTokens));

    # Debug output
    say STDERR "============================================= DFA";
    $dfa->print('DFA', 2);
    say STDERR Dumper($dfa);
    say STDERR $dfa->dumpAsJson;
    say STDERR "=================================================";

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

    open my $fh, '>', 'mtok-generated.dot';     # plot while we're at it
    say $fh 'digraph dfa {';
    my %dot_states;

    # The following code adapted from Data::DFA::print(), since the docs for
    # Data::DFA don't cover the data layout.
    for my $superStateName (sort { $a <=> $b } keys %$dfa) {
        my $superState = $$dfa{$superStateName};
        my $nfaStates = $superState->nfaStates;
        my $transitions = $superState->transitions;
        my $Final = $superState->final;
        my @outgoing_symbols = sort keys %$transitions;
                #  vv No NFA states
        my @row = ('', $superStateName, $Final ? 'accept' : '',
            ('') x $nsymbols);

        # Fill in the transition table
        for my $outgoing_sym (@outgoing_symbols) {
            my $next_state = $dfa->transitionOnSymbol($superStateName, $outgoing_sym);
            my $sym_idx = first_index { $_ eq $outgoing_sym } @symbols;
            $row[3+$sym_idx] = $next_state;     # 3 => NFA state, DFA state, type

            say $fh "$superStateName -> $next_state [ label = \"$outgoing_sym\" ] ";
            unless($dot_states{$superStateName}){
                $dot_states{$superStateName} = 1;
                say $fh "$superStateName [shape=",
                    ($Final ? 'doublecircle' : 'circle' ),
                    ']';
            }

            unless($dot_states{$next_state}){
                $dot_states{$next_state} = 1;
                say $fh "$next_state [shape=",
                    ($dfa->{$next_state}->final ? 'doublecircle' : 'circle' ),
                    ']';
            }
            # See http://jamie-wong.com/2010/10/16/dfas-and-graphviz-dot/
        } #foreach $outgoing_sym

        push @rows, \@row;
    } #foreach $superStateName

    say $fh '}';
    close $fh;

    # }}}2

    return \@rows;
} #main

# }}}1
sub write_csv { # {{{1

=head2 write_csv

Usage:

    mtok::lexergen::write_csv $filename, $lrRows

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
    my $depth_left = shift;     # note that falsy 0 is valid!
    croak 'Need depth left' unless defined $depth_left;
    my $state = shift;  # note that falsy state '0' is valid!
    croak 'Need current state' unless defined $state;
    my $so_far = shift; # note that falsy '' is valid
    croak 'Need string of transitions so far' unless defined $so_far;

    # TODO stop if there are no final (accepting) states left to process

    my @retval;
    my $indent = ' ' x (2*length($so_far));

$DB::single=1;
    my $dfastate = $$dfa{$state} or die "No state $state in DFA";
    say STDERR "State:", Dumper [$dfastate];
    my $transitions = $dfastate->transitions;
    my $final = $dfastate->final;
    print STDERR "$indent> Trying token sequence << $so_far >> in " .
        ($final ? 'accepting ' : '') . "state $state\n";

    # Is this state one that should emit?
    if($final) {
        keys %$hrTokens;    # Reset the each() iterator
        while( my ($token_friendly_name, $lrToken) = each(%$hrTokens)) {
            print STDERR "$indent  Checking regex $$lrToken[0] for $token_friendly_name\n";
            if($so_far =~ $$lrToken[0]) {
                @retval = ($state, $$lrToken[1]);
                say STDERR "$indent> $state is an accepting state for",
                    " $token_friendly_name / $retval[1]";
                last;
            }
        }
    }

    if($depth_left) {
        # Follow the edges
        my @outgoing_symbols = keys %$transitions;
        for my $outgoing_sym (@outgoing_symbols) {
            my $next_state = $dfa->transitionOnSymbol($state, $outgoing_sym);
            next if $next_state eq $state;
            print STDERR "$indent> transition from $state on << $outgoing_sym >> to $next_state\n";
            push @retval, _dfs($hrTokens, $dfa, $depth_left-1, $next_state,
                                $so_far . $outgoing_sym);
        }
    }

    return @retval;
} #_dfs()

# }}}1
sub import { # {{{1
    my $target = caller;

    # Copy symbols listed in @EXPORT first, in case @_ gets trashed later.
    mtok::lexergen->export_to_level(1, @_);

    # Re-export Data::DFA
    Data::DFA->import::into($target, qw(:all));
}
# }}}1
1;
__END__
# Rest of the docs {{{1

=head1 AUTHOR

Christopher White, C<cxwembedded at gmail.com>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc mtok::lexergen

You can also look for information in the GitHub repo:
L<https://github.com/cxw42/do-not-self-host>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 Christopher White.  All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the the ISC License. Details are in the LICENSE
file accompanying this distribution.

=cut

# }}}1
# vi: set fdm=marker fo-=ro:
