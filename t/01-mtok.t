use Test::More;
use IPC::Run3;
use Data::Dumper;

my $in, $out, $err;

sub test {
    my $in = shift;
    my $out, $err;

    run3(['./ngb', 'mtok/mtok.ngb'], \$in, \$out, \$err);

    foreach my $lrTest (@_) {
        my ($which, $match, $name) = @$lrTest;
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
    ['out', 'IH$_42fooEA', 'Complex identifier name']);

test('_42foo', ['err', '', 'No stderr'],
    ['out', 'BG_42fooEA', 'Complex bareword name']);

# Operator punctuation

for my $op (split //, '()"\[\]^*/+,;\\') {
    test($op, ['err','','No stderr'],
        ['out', "${op}B${op}EA", "Operator $op"]);
}

# TODO test empty input

done_testing();
