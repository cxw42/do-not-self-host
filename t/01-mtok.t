use Test::More;
use IPC::Run3;

my $in, $out, $err;

$in='$foo->$bar=1-2 ';  # A reasonable initial test
run3(['./ngb', 'mtok/mtok.ngb'], \$in, \$out, \$err);
is($err, '', 'No stderr');
is($out, 'IE$foo' . 'wC->' . 'IE$bar' . '=B=' . 'NB1' . '-B-' . 'NB2' .
        'RB ' . 'EA',
        'Tokenizes successfully');

done_testing();
