# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib;


use Carp;


# Copies options from an option/argument list to a target hash,
# removing the leading '-' characters from the option names,
# and optionally prefixing the result with a prefix string.
# Mandatory arguments:
# -target => Reference to hash which should receive the results.
# -source => Reference to argument list to be checked.
# Optional arguments:
# -options => Reference to flat list of (option => default) pairs.
# -arguments => Reference to list of mandatory arguments.
# -prefix => Prefix string to be prepended to target hash keys.
# -rename =>
#  Reference to flat list of (old_name => new_name) pairs.
#  When an option or argument old_name is encountered, new_name
#  will be used instead.
#  However, in order to document which old_name has been
#  specified originally, the hash key for old_name will also
#  be set (to a boolean 'true' value).
#  Furthermore, all arguments or options mapped to the same
#  new_name are considered to be mutually exclusive.
#  Mutually excluded mandatory arguments will no longer be
#  mandatory.
#  All options mapped to the same name must also provide the
#  same default value.
# -mutual_exclusions =>
#  Reference to list of key lists.
#  Each key list specifies a set of option/argument keys which
#  are not allowed to used together. The key names will be
#  checked before any renaming operation takes place.
#  Note that it is not necessary to define mutual exclusions
#  for -rename entries, as this is done implicitly.
sub HandleOptions {
   my($s, $o, $a, %r, %n, %f, $p, $t, $k, $b, %x);
   $p= '';
   foreach (@_) {
      if (defined $k) {
         &{
            ${{
                 -source => sub {$s= $_}
               , -target => sub {$t= $_}
               , -prefix => sub {$p= $_}
               , -rename => sub {%r= @$_}
               , -mutual_exclusions => sub {
                  my($g, $f, $t);
                  foreach $g (@$_) {
                     foreach $f (@$g) {
                        foreach $t (@$g) {
                           next if $f eq $t;
                           $x{$f}= [] unless exists $x{$f};
                           push @{$x{$f}}, $t;
                        }
                     }
                  }
               }
               , -options => sub {$o= $_}
               , -arguments => sub {$a= $_}
            }}{$k} || sub {
               croak "unknown internal argument '$k'";
            }
         };
         undef $k;
      } else {
         $k= $_;
      }
   }
   croak "missing value for internal argument '$k'" if $k;
   croak "no -target has been specified" unless $t;
   # Collect mandatory arguments.
   foreach (@$a) {
      $n{$r{$_} || $_}= 0;
   }
   # Collect allowed options and defaults.
   foreach (@{$o || []}) {
      if (defined $k) {
         $t->{$k}= $_;
         undef $k;
      } else {
         $k= $p . ($r{$_} || $_);
      }
   }
   croak "missing value for last internal -options argument" if $k;
   # Process source argument list.
   foreach (@{$s || croak "no -source arguments have been specified"}) {
      if (defined $k) {
         $t->{$k}= $_;
         undef $k;
      } else {
         croak "illegal undef() option key" unless defined $_;
         croak "missing dash in option key '$_'" if substr($_, 0, 1) ne '-';
         $b= substr $_, 1;
         croak "option '$_' conflicts with previous options" if $f{$b};
         $f{$b}= 1; # Forbidden in further processing.
         if ($x{$b}) {
            $f{$_}= 1 foreach @{$x{$b}};
         }
         if (exists $r{$b}) {
            $t->{$p . $b}= 1; # Annotate original name.
            $b= $r{$b};
            croak "option '$_' conflicts with previous options" if $f{$b};
            $f{$b}= 1;
         }
         $k= $p . $b;
         if (exists $n{$b}) {
            # Needed argument.
            delete $n{$b}; # No longer needed.
         } else {
            # Must be option (with assigned default value) then.
            croak "unknown option '$_'" unless exists $t->{$k};
         }
      }
   }
   croak "missing value for last argument" if $k;
   # Check for missing arguments.
   if (%n) {
      my(@a, @v, $n);
      $n= 0;
      foreach $k (keys %n) {
         @v= ();
         while (($b, $t)= each %r) {
            push @v, $b if $t eq $k;
         }
         @v= $k unless @v;
         $n+= @v;
         push @a, join '/', map "-$_", @v;
      }
      $t= ($n == 1 ? "argument" : "arguments") . " " . join ' and ', @a;
      croak "Missing required $t";
   }
}


1;
