use rlib 'lib';
use DTest;
use Test::Cmd;
use File::Slurp;

sub test {  # Run ngb and test the output {{{1
    state $testnum = 0;     # which test this is

    my $in = shift;
    my ($out, $err, $result);

    my %args = %{+shift} if(@_ && ref($_[0]) eq 'HASH');

    my $test = Test::Cmd->new(prog=>'./ngbasm.py', workdir=>'') or
        die "Could not create test object for intput $in";

    my $wasrun;
    local *runme = sub {
        return if $wasrun;

        $test->write('src', $in);
        my $status = $test->run(
            args => "@{[$test->workpath('src')]} @{[$test->workpath('dest')]}"
        );

        if($args{shouldfail}) {
            die "Test should have failed but didn't" unless $status!=0;
        } else {
            die "Test should have passed but didn't" unless $status==0;
        }

        $out = $test->stdout;
        $err = $test->stderr;
        $test->read(\$result, 'dest');
        diag('Got result ' . unpack('H*',$result));
        $wasrun = 1;
    };

    foreach my $lrTest (@_) {
        my ($which, $match, $name) = @$lrTest;
        #$match =~ s/$T/tokencopy($in)/e;

        SKIP: if($which eq 'out') {
            ++$testnum;
            skip "Not this time", 1 if 0;   # TODO skip if prove(1) didn't ask us to run this one
            runme();
            is($out, $match, $name);
        }

        SKIP: if($which eq 'err') {
            ++$testnum;
            skip "Not this time", 1 if 0;   # TODO skip if prove(1) didn't ask us to run this one
            runme();
            is($err, $match, $name);
        }

        SKIP: if($which eq 'result') {
            ++$testnum;
            skip "Not this time", 1 if 0;   # TODO skip if prove(1) didn't ask us to run this one
            runme();
            is(unpack('H*',$result), unpack('H*',$match), $name);
                # unpack => test string against string.  unpack() takes
                # a string and returns, in this case, a different string.
        }

    } #foreach test
} # test() }}}1

##############################################################################
# Tests

# Generate instructions
sub instrs { return pack('l<*', @_); }

# Standard preamble for &main as the first thing in the file.
my $preamble = instrs(1, 3, 7);

# `end` instruction, which ngbasm always adds
my $end = instrs(26);

test(":main\nnop", ['err', '', 'No stderr'],
    ['result', $preamble . instrs(0) . $end , 'Single NOP']);

done_testing();

