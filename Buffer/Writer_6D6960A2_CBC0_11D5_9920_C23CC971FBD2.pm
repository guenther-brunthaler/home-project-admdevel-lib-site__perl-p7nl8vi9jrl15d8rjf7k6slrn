# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib::Buffer::Writer;
our $VERSION= '1.0';


use Lib::Armor_F467BD40_CBA4_11D5_9920_C23CC971FBD2;
use Lib::PackPUI_0EEED08C_DA7D_11D5_98D3_0050BACC8FE1;


# Instance variables (hash key prefix is 'wra2_'):
#
# $self->{wra2_buf}: output buffer.


sub Writer {
   my $self= shift;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   $self->{wra2_buf}= '';
   $self;
}


# Write a binary string.
sub write {
   my($self, $string)= @_;
   $self->{wra2_buf}.= $string;
}


# Write a portable unsigned integer.
# If a second argument is provided, the PUI will be written in such a
# way that it has the same length as if the second argument would
# have been written instead (assuming the second number is larger).
# This allows to write a PUI that can be replaced by a larger number later.
sub write_pui {
   my $self= shift;
   $self->{wra2_buf}.= Lib::PackPUI @_;
}


# Writes a binary string prefixed by its length.
sub write_string {
   my($self, $string)= @_;
   $self->write_pui(length $string);
   $self->write($string);
}


# Returns a reference to the buffer containing the written data.
sub get_buffer {
   \shift->{wra2_buf};
}


# Write a string Guenther Brunthaler-style radix-64 armored.
sub write_armored {
   my($self, $data)= @_;
   $self->write(Lib::Armor($data));
}


1;
