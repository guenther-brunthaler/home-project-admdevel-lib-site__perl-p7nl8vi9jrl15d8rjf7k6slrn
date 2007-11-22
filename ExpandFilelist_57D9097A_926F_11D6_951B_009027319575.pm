# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


require 5.008;
use strict;


package ExpandFilelist_57D9097A_926F_11D6_951B_009027319575;
use LongPkgAlias_F1961100_9F4D_11D9_BFF3_00A0C9EF1631;
import_from_short_name_alias_instead;


# Functions for command line argument expansion using optional
# wildcards or (possibly nested) response files.


package Lib::ExpandFilelist;


use Carp;
use File::Glob qw(:glob);
use File::Spec;
use File::Spec::Unix;
use Exporter qw(import);
use PkgVersion_B9A179B0_9FB3_11D9_BFF3_00A0C9EF1631;


# Version substrings: "4" => 4, "5.6" => 5.006, "7.8.9" => 7.008009
our $VERSION= extract_VERSION_from '$Revision: 11 $';
our @EXPORT= qw(ExpandFilelist);


# To be included into an application usage help message.
our $HELP= <<"END"; chomp $HELP;
   A list of one or more filenames which may include shell wildcards.
   If a list entry starts with the character "\@", the characters
   following the "\@" are considered to be the name of a response file.
   Response files will be read as text files, and the contents of all
   the lines in that file will be added to the file pattern list to
   be expanded. This procedure will then be re-applied recursively.
   This means the contents of response files are allowed to include
   references to other response files.
END


sub parse_words_ku7j8jgnqwt5700aqmaibfi6f {
   my $line= shift;
   $line =~ s/^\s*(.*?)\s*$/$1/;
   split /\s+/, $line;
}


sub parse_args_mqt7hig404fslzse3x4uvwhcv {
   my $line= shift;
   my($s, $e, @r);
   $line =~ s/^\s*(.*?)\s*$/$1/;
   for ($s= 0; ($e= index($line, '"', $s)) >= 0; $s= $e) {
      if ($e > $s) {
         # Unquoted prefix or infix.
         push @r
            , parse_words_ku7j8jgnqwt5700aqmaibfi6f(substr $line, $s, $e - $s)
         ;
      }
      # Quoted string.
      $s= $e + 1;
      if (($e= index $line, '"', $s) >= 0) {
         # Terminating quote present.
         push @r, substr($line, $s, $e++ - $s);
      }
      else {
         # Missing terminating quote.
         push @r, substr($line, $s);
         $e= length $line;
      }
   }
   if ($s < length($line)) {
      # Unquoted suffix.
      push @r, parse_words_ku7j8jgnqwt5700aqmaibfi6f(substr $line, $s);
   }
   @r;
}


# Expands response file specifications ('@file') and optionally globs.
# Accepts a list reference and a list of options:
# -expand_globs => 1: Expand any file globs
# -log => undef: Support logging.
# -log => 1: log to STDOUT.
# -log => *LOGFILE{IO}: Define output log file for expansion events
# -log => \&callback: Will be called back with output string as argument
# -log => [\&callback, args ...]: Same, but arguments will also be passed
# Note: Literal '@' at the beginning of a file name must be doubled,
# e. g. "@@@@a@t@" means literal file "@@a@t@",
# but "@@@@@a@t@" means response file "@@a@t@".
sub ExpandFilelist {
   my($list, %opt)= @_;
   my($log, @args);
   if (!exists $opt{-log} || !$opt{-log}) {
      $log= sub {};
   }
   elsif (ref $opt{-log} eq 'CODE') {
      $log= $opt{-log};
   }
   elsif (ref $opt{-log} eq 'ARRAY') {
      @args= @{$opt{-log}};
      $log= shift @args;
   }
   else {
      $log= sub {
         my($t, $fh)= @_;
         print $fh $t, "\n"
      };
      @args= substr(ref($opt{-log}), 0, 2) eq 'IO' ? $opt{-log} : *STDOUT{IO};
   }
   for (my $i= $[; $i < @$list; ++$i) {
      $list->[$i] =~ s(
         ^( [@]* )
      )(
         '@' x (length($1) >> 1)
      )ex;
      if (length($1) & 1) {
         local *FLIST;
         my($fname, @fl, $line);
         $fname= substr($list->[$i], 1);
         open FLIST, '<',  $fname
            or croak "cannot open response file '$fname'"
         ;
         &{$log}("including response file '$fname'...", @args);
         while (defined($line= <FLIST>)) {
            push @fl, parse_args_mqt7hig404fslzse3x4uvwhcv($line);
         }
         close FLIST or croak $!;
         {
            local $opt{-expand_globs};
            $opt{-expand_globs}= 1;
            ExpandFilelist(\@fl, %opt);
         }
         splice @$list, $i, 1, @fl;
         redo;
      }
      elsif ($opt{-expand_globs}) {
         my(@xp);
         if ($File::Spec::ISA[0] ne 'Unix') {
            my $e;
            my $a= File::Spec->file_name_is_absolute($list->[$i]);
            my($v, $d, $f)=
               File::Spec->splitpath(File::Spec->rel2abs($list->[$i]))
            ;
            my @d= File::Spec->splitdir($d);
            for (my $i= 0; $i < @d; ) {
               if ($d[$i] eq File::Spec->curdir()) {
                  splice @d, $i, 1;
                  next;
               }
               if ($d[$i] eq File::Spec->updir() && $i > 0) {
                  splice @d, --$i, 2;
                  next;
               }
               ++$i;
            }
            if ($a) {
               die if $v eq '';
               for ($e= 0; @d > 0 && $d[0] eq ''; ++$e) {shift @d}
               # Fake volume as first path component.
               unshift @d, $v ;
               $v= '';
            }
            else {
               $f= File::Spec->catpath($v, File::Spec->catdir(@d), $f);
               ($v, $d, $f)= File::Spec->splitpath(File::Spec->abs2rel($f));
               die if $v ne '';
               @d= File::Spec->splitdir($d);
            }
            $d= File::Spec::Unix->catdir(@d);
            $f= File::Spec::Unix->catpath($v, $d, $f);
            @xp= bsd_glob($f);
            if ($File::Spec::ISA[0] ne 'Unix') {
               foreach (@xp) {
                  ($v, $d, $f)= File::Spec::Unix->splitpath($_);
                  die if $v ne '';
                  @d= File::Spec::Unix->splitdir($d);
                  if ($a) {
                     $v= shift @d;
                     unshift @d, ('') x $e;
                  }
                  $d= File::Spec->catdir(@d);
                  $_= File::Spec->catpath($v, $d, $f);
               }
            }
         }
         if (@xp > 1) {
            &{$log}(
                  "Expanding filename pattern '$list->[$i]' into "
                  . scalar(@xp) . " items ..."
               , @args
            );
         }
         splice @$list, $i, 1, @xp;
         $i+= @xp - 1;
      }
   }
}


1;
