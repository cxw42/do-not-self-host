# DTest.pm: test kit for do-not-self-host

package DTest;

use parent 'Exporter';
use Import::Into;

use strict;
use warnings;
use Test::More;
use IPC::Run3;

sub import {
    my $target = caller;

    # Copy symbols listed in @EXPORT first, in case @_ gets trashed later.
    DTest->export_to_level(1, @_);

    # Re-export pragmas
    constant->import::into($target, {true => !!1, false => !!0});
    foreach my $pragma (qw(strict warnings)) {
        ${pragma}->import::into($target);
    };

    # Re-export packages
    foreach my $pkg (qw(Test::More IPC::Run3)) {
        ${pkg}->import::into($target);
    }

    Carp->import::into($target, qw(carp croak));
}

1;

