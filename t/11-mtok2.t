use rlib 'lib';
use DTest;
use Test::OnlySome::RerunFailed;    # verbose => 1;

# TODO read the token codes from minhi-constants.nas in case they ever change

# Variables used by test() {{{1

# A placeholder for the tokencopy() output
our $T;
*T = \'You would be crazy to actually put this in a test string!';

# }}}1

sub test {  # Run ngb and test the output {{{1
    my $in = shift;
    my ($out, $err);
    my $wasrun;

    # A runner - a local sub so we don't re-run if the tests are skipped.
    local *runme = sub {
        run3(['./ngb', 'mtok/mtok2.ngb'], \$in, \$out, \$err) unless $wasrun;
        $wasrun = 1;
    };

    foreach my $lrTest (@_) {
        my ($which, $match, $name) = @$lrTest;
        $match =~ s/$T/tokencopy($in)/e;

        if($which eq 'out') {
            os { runme(); is($out, $match, $name); }
        }

        if($which eq 'err') {
            os { runme(); is($err, $match, $name); }
        }
    }
} # test() }}}1

##############################################################################
# Tests, in the order they appear in minhi-constants.nas.

# General TODO: add failure tests for all of these
# General TODO: Break this into multiple *.t files so prove --state=failed
# will work.

# A reasonable initial test
test(   #'$foo->$bar:=1-2 ',
    'IE$foo' . 'wC->' . 'IE$bar' . '=C:=' . 'NB1' . '-B-' . 'NB2' .
    'RB ' . 'EA',   # The tokenized output from mtok
    ['err', '', 'No stderr'],
    ['out',
        'IE$foo' . 'wC->' . 'IE$bar' . '=C:=' . 'NB1' . '-B-' . 'NB2' .
        'EA',
        'Drops whitespace']
);

# Test empty input (T_EOF)
test('', ['err', '', 'No stderr'], ['out', 'EA', 'Empty input']);

# Whitespace (T_IGNORE)

for my $ws (" ", "  ", "\t", "\r", "\n", "\r\n", "  \t\t   \r  \n\r\n") {
    test('R' . tokencopy($ws), ['err', '', 'No stderr'],
        ['out', "EA", "Whitespace: " . unpack('H*', $ws)]);
}

# Identifiers and barewords

for my $id ('$_42foo', '@a', '%b', '#c', '!d', '&e') {
    my $tok = 'I' . tokencopy($id);
    test($tok, ['err', '', 'No stderr'],
        ['out', "${tok}EA", "Identifier $id"]);
        # ${T} stands for the numout-format length plus text of the input
}

for my $bw ('_42foo', 'a', 'a1', 'a_1', 'bkdhjkhdfgkjhdfgkjdhfgkjdhfgkjdhfg') {
    my $tok = 'B' . tokencopy($bw);
    test($tok, ['err', '', 'No stderr'],
        ['out', "${tok}EA", "Bareword $bw"]);
}

# Numbers

for my $num (1, 12, 123, 1234, 12345) {
    my $tok = 'N' . tokencopy($num);
    test($tok, ['err', '', 'No stderr'],
        ['out', "${tok}EA", "Digit $num"]);
}

# Operator punctuation

for my $op (split //, '()"\[\]^*/+,;\\') {
    my $tok = $op . tokencopy($op);
    test($tok, ['err','','No stderr'],
        ['out', "${tok}EA", "Operator $op"]);
}

# Standalone operators

            #   op   T_*
for my $hrOp (['??', '?'], ['::', ':'], ['-', '-'], ['<=', '{'],
                ['>=', '}'], ['<', '<'], ['>', '>'], ['=', '~'],
                ['<>','!'], ['<=>', 's'], ['->', 'w'], [':=', '=']) {
    my $tok = $hrOp->[1] . tokencopy($hrOp->[0]);
    test($tok, ['err', '', 'No stderr'],
        ['out', "${tok}EA", "Operator $hrOp->[0]"]);
}

done_testing();

# vi: set fdm=marker: #
