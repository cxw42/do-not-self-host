use rlib 'lib';
use DTest;

# TODO read the token codes from minhi-constants.nas in case they ever change

sub int2ascii { # The Perl port of the numout instruction from ngb.c {{{1
    my $val = +shift or croak;
    my $retval = '';
    my $first = 1;

    # Generate LSB to MSB
    while(1) {
        use integer;
        my $digit = chr( ($val % 26) + ord($first ? 'A' : 'a') );
            # last char is uppercase
        $retval = "${digit}${retval}";
        $first = false;
    } continue {
        use integer;
        $val /= 26;
        last unless $val>0;
    }

    return $retval;
} #int2ascii }}}1

sub alen { # Strlen, but returns the result in numout form  {{{1
    my $token = shift or croak;
    return int2ascii(length($token));
} #alen }}}1

sub tokencopy { # Return the string we expect as a copy of the input. {{{1
    # Warning: not reentrant
    my $token = shift or croak;
    return alen($token) . $token;
} #tokencopy }}}1

# A placeholder for the tokencopy() output {{{1
our $T;
*T = \'You would be crazy to actually put this in a test string!';
# }}}1

sub test {  # Run ngb and test the output {{{1
    my $in = shift;
    my ($out, $err);

    run3(['./ngb', 'mtok/mtok.ngb'], \$in, \$out, \$err);

    foreach my $lrTest (@_) {
        my ($which, $match, $name) = @$lrTest;
        $match =~ s/$T/tokencopy($in)/e;
        is($out, $match, $name) if $which eq 'out';
        is($err, $match, $name) if $which eq 'err';
    }
} # test() }}}1

##############################################################################
# Tests, in the order they appear in minhi-constants.nas.

# General TODO: add failure tests for all of these

# A reasonable initial test
test('$foo->$bar=1-2 ',
    ['err', '', 'No stderr'],
    ['out', 'IE$foo' . 'wC->' . 'IE$bar' . '=B=' . 'NB1' . '-B-' . 'NB2' .
        'RB ' . 'EA', 'Tokenizes successfully']
);

# TODO test empty input (T_EOF)

# Whitespace (T_IGNORE)

for my $ws (" ", "  ", "\t", "\r", "\n", "\r\n", "  \t\t   \r  \n\r\n") {
    test($ws, ['err', '', 'No stderr'],
        ['out', "R${T}EA", "Whitespace: " . unpack('H*', $ws)]);
}

# Identifiers and barewords

for my $id ('$_42foo', '@a', '%b', '#c', '!d', '&e') {
    test($id, ['err', '', 'No stderr'],
        ['out', "I${T}EA", "Identifier $id"]);
        # ${T} stands for the numout-format length plus text of the input
}

for my $bw ('_42foo', 'a', 'a1', 'a_1', 'bkdhjkhdfgkjhdfgkjdhfgkjdhfgkjdhfg') {
    test($bw, ['err', '', 'No stderr'],
        ['out', "B${T}EA", "Bareword $bw"]);
}

# Numbers

for my $num (1, 12, 123, 1234, 12345) {
    test($num, ['err', '', 'No stderr'],
        ['out', "N${T}EA", "Digit $num"]);
}

# Operator punctuation

for my $op (split //, '()"\[\]^*/+,;\\') {
    test($op, ['err','','No stderr'],
        ['out', "${op}${T}EA", "Operator $op"]);
}

# Standalone operators

            #   op   T_*
for my $hrOp (['??', '?'], ['::', ':'], ['-', '-'], ['<=', '{'],
                ['>=', '}'], ['<', '<'], ['>', '>'], ['==', '~'],
                ['<>','!'], ['<=>', 's'], ['->', 'w'], ['=', '=']) {
    test($hrOp->[0], ['err', '', 'No stderr'],
        ['out', "$hrOp->[1]${T}EA",
            "Operator $hrOp->[0]"]);
}

done_testing();

# vi: set fdm=marker: #
