use rlib 'lib';
use DTest;
use Test::Cmd;
use File::Slurp;
#use Data::Dumper;

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
        #diag('Got result ' . unpack('H*',$result));
        $wasrun = 1;
    };

    foreach my $lrTest (@_) {
        my ($which, $match, $name) = @$lrTest;
        $name //= "Look for $match in $which of $in";
        #$match =~ s/$T/tokencopy($in)/e;

        local *check = sub {
            if(ref $match ne 'SCALAR') {
                is(shift, $match, $name);
            } else {
                diag("Checking if it contains $$match");
                contains_string(shift, $$match, $name);
            }
        };

        SKIP: if($which eq 'out') {
            ++$testnum;
            skip "Not this time", 1 if 0;   # TODO skip if prove(1) didn't ask us to run this one
            runme();
            check($out);
        }

        SKIP: if($which eq 'err') {
            ++$testnum;
            skip "Not this time", 1 if 0;   # TODO skip if prove(1) didn't ask us to run this one
            runme();
            diag($err);
            check($err);
        }

        SKIP: if($which eq 'result') {  # Note: substrings not supported
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
sub asm { return pack('l<*', @_); }

# Standard preamble for &main as the first thing in the file.
my $preamble = asm(1, 3, 7);

# `end` instruction, which ngbasm always adds
my $end = asm(26);

my @instrs = (
    'nop',
    'lit',
    'dup',
    'drop',
    'swap',
    'push',
    'pop',
    'jump',
    'call',
    'ccall',
    'return',
    'eq',
    'neq',
    'lt',
    'gt',
    'fetch',
    'store',
    'add',
    'sub',
    'mul',
    'divmod',
    'and',
    'or',
    'xor',
    'shift',
    'zret',
    'end',

    'in',
    'out',
    'cjump',
    'iseof',
    'numin',
    'numout',
    'pull',
);

# Test unknown instruction.  \'' => contains, not is.
test(":main\nnotaninstructionreallyforsure", { shouldfail=>true },
    ['err', \'Unknown instruction', 'Unknown instructions cause failure']);

done_testing;
exit;

# Test everything but lit, since only lit has a required argument
while( my ($idx, $opname) = each @instrs ) {
    next if $opname eq 'lit';
    test(":main\n$opname", ['err', '', 'No stderr'],
        ['result', $preamble . asm($idx) . $end , "Single $opname"]);
}

# Test lit
test(":main\nlit 42", ['err', '', 'No stderr'],
    ['result', $preamble . asm(1, 42) . $end , "lit with operand"]);

# Test lit without operand
test(":main\nlit", {shouldfail=>true},
    ['err', \'requires an operand', 'Lit requires operand']);

done_testing();

