# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib::Adler16;
# Simple ADLER-16 checksum.
our $VERSION= '1.00';


use Lib::HandleOptions_F467BD47_CBA4_11D5_9920_C23CC971FBD2;
use Carp;


# Instance variables:
# Prefix is 'bd47_'.
# $self->{bd47_low}.
# $self->{bd47_high}.


# Creates a new object.
sub new {
   my($self)= @_;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   $self->clear;
   $self;
}


# Preset the checksum for an empty object.
sub clear {
   my $self= shift;
   ($self->{bd47_low}, $self->{bd47_high})= (1, 0);
}


# Returns the current checksum.
sub get {
   my $self= shift;
   $self->{bd47_high} << 8 | $self->{bd47_low};
}


sub _N {
   # Largest prime less than 2 ** 8.
   251;
}


# Updates the current checksum by including more bytes.
sub add {
   my($self, $s)= ($_[0], \$_[1]);
   my($i, $e);
   my($s1, $s2)= ($self->{bd47_low}, $self->{bd47_high});
   $e= length $$s;
   for ($i= 0; $i < $e; ++$i) {
      # $s1= ($s1 + char[$i]) % _N
      $s1+= unpack 'C', substr $$s, $i, 1;
      $s1-= _N while $s1 >= _N;
      # $s2= ($s2 + $s1) % _N
      $s2+= $s1;
      $s2-= _N while $s2 >= _N;
   }
   ($self->{bd47_low}, $self->{bd47_high})= ($s1, $s2);
}


# Static function: Creates a temporary object, adds the supplied string
# and returns its checksum.
sub sum {
   my $obj= new __PACKAGE__;
   $obj->add(shift);
   $obj->get;
}
