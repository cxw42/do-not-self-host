use rlib 'lib';
use DTest;

# TODO read the token codes from minhi-constants.nas in case they ever change

# The Perl port of the numout instruction from ngb.c
sub int2ascii {
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
} #int2ascii

# Strlen, but returns the result in numout form
sub alen {
    my $token = shift or croak;
    return int2ascii(length($token));
} #alen

# Return the string we expect as a copy of the input.  Warning: not reentrant
sub tokencopy {
    my $token = shift or croak;
    return alen($token) . $token;
} #tokencopy

# A placeholder for the tokencopy() output
our $T;
*T = \'You would be crazy to actually put this in a test string!';

sub test {
    my $in = shift;
    my ($out, $err);

    run3(['./ngb', 'mtok/mtok.ngb'], \$in, \$out, \$err);

    foreach my $lrTest (@_) {
        my ($which, $match, $name) = @$lrTest;
        $match =~ s/$T/tokencopy($in)/e;
        is($out, $match, $name) if $which eq 'out';
        is($err, $match, $name) if $which eq 'err';
    }
} # test()

# A reasonable initial test
test('$foo->$bar=1-2 ',
    ['err', '', 'No stderr'],
    ['out', 'IE$foo' . 'wC->' . 'IE$bar' . '=B=' . 'NB1' . '-B-' . 'NB2' .
        'RB ' . 'EA', 'Tokenizes successfully']
);

# Identifiers and barewords

test('$_42foo', ['err', '', 'No stderr'],
    ['out', "I${T}EA", 'Complex identifier name']);
    # ${T} stands for the numout-format length plus text of the input

test('_42foo', ['err', '', 'No stderr'],
    ['out', "B${T}EA", 'Complex bareword name']);

# Operator punctuation

for my $op (split //, '()"\[\]^*/+,;\\') {
    test($op, ['err','','No stderr'],
        ['out', "${op}${T}EA", "Operator $op"]);
}

# Numbers

for my $num (1, 12, 123, 1234, 12345) {
    test($num, ['err', '', 'No stderr'],
        ['out', "N${T}EA", "Digit $num"]);
}

# Standalone operators.  TODO add the rest of these.

for my $hrOp (['??', '?'], ['::', ':']) {
    test($hrOp->[0], ['err', '', 'No stderr'],
        ['out', "$hrOp->[1]${T}EA",
            "Operator $hrOp->[0]"]);
}

# Whitespace
for my $ws (" ", "  ", "\t", "\r", "\n", "\r\n", "  \t\t   \r  \n\r\n") {
    test($ws, ['err', '', 'No stderr'],
        ['out', "R${T}EA", "Whitespace: " . unpack('H*', $ws)]);
}

# TODO test empty input

done_testing();
