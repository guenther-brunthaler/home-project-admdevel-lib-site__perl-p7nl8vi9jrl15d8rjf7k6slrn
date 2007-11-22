# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision$
# $Date$
# $Author$
# $State$
# $xsa1$


use strict;


package Lib::TOOLS::SettingsFile;


use Carp;
use Lib::HandleOptions_F467BD47_CBA4_11D5_9920_C23CC971FBD2;


sub Process {
   my(%myopt, %opt);
   Lib::HandleOptions(
      -source => \@_, -target => \%myopt,
      -arguments => [qw/source target window_title headline do_button options/]
   );
   %opt= @{$myopt{source}} ? @{$myopt{source}} : qw/--gui 1/;
   {
      my $window_title= $myopt{window_title};
      my $headline= $myopt{headline};
      my $do_button= $myopt{do_button};
      my %supp= @{$myopt{options}};
      my($defr, $defw);
      $defw= $0;
      $defw =~ s!.*?([^./\\]+)(?:\.[^\\/]*)?$!$1.settings! or die;
      $defr= $defw;
      foreach (keys %opt) {
         if (exists $supp{$_}) {
            $opt{substr $_, 2}= $opt{$_};
            delete $opt{$_};
         }
         else {
            foreach (values %supp) {$_= ": $_\n"}
            croak "unknown option '$_'!\nMust be one of:\n" . join('', %supp) . "\n";
         }
      }
      if (exists $opt{settingsfile}) {
         $defr= $defw= $opt{settingsfile};
      }
      else {
         if (-f $defw && -r _) {
            $opt{settingsfile}= $defw;
         }
         else {
            $defr= $0;
            if (
               $defr =~ s!\.[^\\/]*$!.settings!
               && -f $defr && -r _
            ) {
               $opt{settingsfile}= $defw;
            }
            else {
               undef $defr;
            }
         }
      }
      if (defined $defr) {
         if (open SETTINGS, '<', $defr) {
            while (<SETTINGS>) {
               chomp;
               my($opt, $value)= split /\s+/, $_, 2;
               $value =~ s/^\s*(.*?)\s*$/$1/;
               next unless exists $supp{$opt};
               $opt{substr $opt, 2}= $value unless exists $opt{substr $opt, 2};
            }
            close SETTINGS or croak;
         }
      }
      if ($opt{gui}) {
         $opt{settingsfile}= $defw unless exists $opt{settingsfile};
         use Tk;
         use Tk::Font;
         use Tk::Pane;
         my($wnd, $ow, $f, @p1, $ok);
         $wnd= MainWindow->new(-title => $window_title);
         $wnd->Label(
            -text => $headline, -font => $wnd->Font(-size => 16)
         )->pack;
         $f= $wnd->Scrolled(
            qw/Pane -scrollbars oe -sticky we -gridded y/
         )->pack(qw/-fill both -expand y/);
         my($sw, $help, $f2, $r);
         $r= 0;
         foreach (map [$_, $supp{$_}, ++$r], sort keys %supp) {
            $r= $_->[2] * 2;
            my $t= $_->[1] . ':';
            $t =~ s/./\U$&/;
            $f->Label(-text => $t)->grid(-row => $r, qw/-columnspan 2/);
            $f->Label(
               -text => 'Option ' . $_->[0] . ':'
            )->grid(-row => ++$r, qw/-sticky e/);
            $f->Entry(
               -textvariable => \$opt{substr $_->[0], 2}, qw/-width 30/
            )->grid(-row => $r, qw/-column 1/);
         }
         foreach (
            [$do_button, sub {$ok= 1; $wnd->destroy}],
            ['Quit', [$wnd => 'destroy']]
         ) {
            $wnd->Button(
               -text => $_->[0], -command => $_->[1]
            )->pack(qw/-side right -padx 5 -pady 5/);
         }
         MainLoop;
         exit unless $ok;
      }
   }
   foreach (keys %opt) {
      if (
         exists $opt{$_} && (!defined $opt{$_} || $opt{$_} =~ /^\s*$/)
      ) {
         delete $opt{$_};
      }
   }
   if (exists $opt{settingsfile} && $opt{settingsfile} =~ /\S/) {
      if (open SETTINGS, '>', $opt{settingsfile}) {
         delete $opt{settingsfile};
         foreach (sort keys %opt) {
            print SETTINGS "--$_\t$opt{$_}\n";
         }
         close SETTINGS or croak;
      }
   }
   foreach (keys %opt) {
      $myopt{target}->{$_}= $opt{$_};
   }
}


1;
