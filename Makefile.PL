use 5.010;
use strict;
use warnings;
use version;
use ExtUtils::MakeMaker;
use File::Slurp;
#use File::Spec;

# === Code-based configuration ============================================

# Ignore *.c so that EUMM doesn't add build rules for them to Makefile
# Thanks to https://www.perlmonks.org/?node_id=982933 by Anonymous Monk
sub MY::libscan {
    my( $mm, $file ) = @_;
    return if $file =~  /\.c$/; # SKIP
    return $file;
}

# Hijack the Makefile so that our build steps run instead of EUMM's.
# Also add testhere target.
sub MY::post_initialize {
    my $self = shift;

    # Get the name of the default target
    my $tgt = $self->makemakerdflt_target;
    $tgt =~ s/^(\w+).*/$1/s;

    # Get our actual Makefile, which must not use the "all" target
    my $custom = read_file('Makefile.in', err_mode => 'carp');
    my $custom_tgt = 'custom';
    $custom_tgt = $1 if $custom =~ m/^(\w+):/m;

    # Put our Makefile first.
    return <<EOT;
very_first_target: $custom_tgt
eumm: $tgt

test :: $custom_tgt

$custom

EOT

} # MY::post_initialize

sub MY::postamble {     # TODO also handle Windows nmake syntax (SET vs. export)
    return <<EOT;
# Run the tests from lib rather than blib, and use osprove
testhere: very_first_target
\tosprove -lj4 t/*

testclean:
\t-rm .onlysome.yml

EOT
} #MY::postamble



# === Write the makefile ==================================================

WriteMakefile(
    NAME             => 'NonPerl::DoNotSelfHost',
    AUTHOR           => q{Christopher White <cxwembedded@gmail.com>},
    VERSION          => qv(0.0.1),
    ABSTRACT         => 'Testing support for do-not-self-host',
    LICENSE          => 'open_source',  # ISC, in fact
    MIN_PERL_VERSION => '5.016',    # because of Data::DFA
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
        'File::Slurp' => '0',
        #'File::Spec' => '0',
        'Test::Cmd' => '0',
        #'Test::LongString' => '0',
        'version' => '0.77',
    },
    BUILD_REQUIRES => {
        'Data::DFA' => '0',
        'List::MoreUtils' => '0',
        'List::Util' => '0',
        'Test::More' => '0',
        'Text::CSV' => '0',
    },
    TEST_REQUIRES => {
        'Cwd' => '0',
        'Import::Into' => '0',
        'IPC::Run3' => '0',
        'rlib' => '0',
        'Test::Harness' => '0',
        'Test::OnlySome' => '0.000008',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/cxw42/do-not-self-host.git',
                web  => 'https://github.com/cxw42/do-not-self-host',
            },
        },
    },
);
