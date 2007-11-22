# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision$
# $Date$
# $Author$
# $State$
# $xsa1$


use strict;


package Lib::XSA::Processor_E4DE5730_CA32_11D5_9920_C23CC971FBD2;
# XSA-processor for extracting UUIDs and placing them into
# marked sections within VB source files as 'Enum' or 'PresetUUIDs'.
our $VERSION= '1.1';


use Carp;
use Lib::Armor_F467BD40_CBA4_11D5_9920_C23CC971FBD2;
use Lib::UUID2Bin_F467BD41_CBA4_11D5_9920_C23CC971FBD2;
use Lib::WrSplit_F467BD42_CBA4_11D5_9920_C23CC971FBD2;
use Lib::XSA::SectionProcessor_F467BD4B_CBA4_11D5_9920_C23CC971FBD2;


# Instance variables (hash key prefix is 'pe4_'):
# $self->{pe4_sp}: <Lib::XSA::SectionProcessor>-object.


our $processed_uuid= '{E4DE5730-CA32-11D5-9920-C23CC971FBD2}';


sub new {
   my $self= shift;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   $self->{pe4_sp}= new Lib::XSA::SectionProcessor;
   $self;
}


# Appends all "extern UUID const" declarations from the specified
# file to $u:
# $u->[$INDEX]->{name}: Symbol name.
# $u->[$INDEX]->{comments}->[$LINE]: Comment lines for symbol.
sub get_uuids_from_file {
   my($filename, $u, $fbase)= @_;
   my $maxctx= 20; # Maximum context lines (looking for comments).
   local *IN;
   my(@ll, $i, $j, $c, $t);
   $fbase =~ s!(.*[\\/:]).*!$1! or $fbase= '';
   $filename= $fbase . $filename;
   open IN, '<', $filename or croak "Cannot open file '$filename': $!";
   $i= 0;
   while (<IN>) {
      $i= $maxctx if $i == 0;
      $ll[--$i]= $_;
      if (/^\s*extern\s+UUID\s+const\s+(\w+)/) {
         push @$u, {name => $1, comments => $c= []};
         for ($j= $i;;) {
            $j= 0 if ++$j == @ll;
            last unless defined($t= $ll[$j]);
            last unless $t =~ m!^\s*//\s*(.*?)\s*$!;
            push @$c, $1;
         }
      }
   }
   close IN or croak;
}


# Update a source file.
# Arguments:
# -filename => filename
# Options:
# -emulate => if specified, the original file will not be replaced.
#  Instead, an additional file with the same name as the original file
#  plus the extension '.new' added will be created.
sub process {
   my($self, %opt)= @_;
   my(@u, @i);
   $self->{pe4_sp}->read(
      -filename => $opt{-filename},
      -emulate => $opt{-emulate},
      -uuid => $processed_uuid,
      -sections => [
         [
            -begin => 'begin_commands',
            -end => 'end_commands',
            -handler => sub {
               my($reader)= shift;
               my($s);
               while ($s= $reader->read) {
                  unless ($s =~ /^\s*'Import (all) UUIDs from file "(.*)"\.\s*$/) {
                     croak "XSA-processor cannot understand this command."
                  }
                  get_uuids_from_file($2, \@i, $opt{-filename});
               }
            }
         ],
         [
            -begin => 'begin_local_UUIDs_to_include',
            -end => 'end_local_UUIDs_to_include',
            -handler => sub {
               my($reader)= shift;
               my($s);
               while ($s= $reader->read) {
                  if ($s =~ /^\s*([^'\s].*?)\s*$/) {
                     push @u, {name => $1};
                  }
               }
            }
         ],
         [
            -begin => 'begin_imported_UUIDs_to_replace',
            -end => 'end_imported_UUIDs_to_replace',
            -handler => sub {
               push @u, @i;
               splice @i;
            }
         ],
         [
            -begin => 'begin_presetUUIDs_to_replace',
            -end => 'end_presetUUIDs_to_replace'
         ],
      ]
   );
   $self->{pe4_sp}->update(
      -filename => $opt{-filename},
      -emulate => $opt{-emulate},
      -uuid => $processed_uuid,
      -sections => [
         [
            -begin => 'begin_commands',
            -end => 'end_commands',
         ],
         [
            -begin => 'begin_local_UUIDs_to_include',
            -end => 'end_local_UUIDs_to_include',
         ],
         [
            -begin => 'begin_imported_UUIDs_to_replace',
            -end => 'end_imported_UUIDs_to_replace',
            -handler => sub {
               my($updater)= shift;
               foreach (@u) {
                  if (exists $_->{comments}) {
                     foreach (@{$_->{comments}}) {
                        $updater->write("'" . $_);
                     }
                     $updater->write($_->{name});
                  }
               }
            }
         ],
         [
            -begin => 'begin_presetUUIDs_to_replace',
            -end => 'end_presetUUIDs_to_replace',
            -handler => sub {
               my $updater= shift;
               Lib::WrSplit(
                  -callback => [
                     sub {
                        my($text, $updater)= @_;
                        $updater->write($text);
                     },
                     $updater
                  ],
                  -text => Lib::Armor(
                     join('', map(Lib::UUID2Bin(substr $_->{name}, -36), @u))
                  ),
                  -initial_prefix => 'Private Const presetUUIDs = "',
                  -final_suffix => '"',
                  -newline_prefix => '& "',
                  -line_suffix => '" _',
               );
            }
         ],
      ]
   );
}


1;
