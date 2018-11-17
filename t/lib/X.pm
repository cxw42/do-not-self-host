#package App::Prove::Plugin::X;
package X;

use Data::Dumper;
use 5.010;

use strict;
  use warnings;
  sub load {
      my ($class, $p) = @_;
      my @args = @{ $p->{args} };
      my $app  = $p->{app_prove};
      print "loading plugin: $class, args: ", join(', ', @args ), "\n";
      # turn on verbosity
      $app->verbose( 1 );
      # set the formatter?
      $app->formatter( $args[1] ) if @args > 1;
      # print some of App::Prove's state:
      for my $attr (qw( jobs quiet really_quiet recurse verbose )) {
          my $val = $app->$attr;
          $val    = 'undef' unless defined( $val );
          print "$attr: $val\n";
      }
      say Dumper($class, $p);

      return 1;
  }
1;

