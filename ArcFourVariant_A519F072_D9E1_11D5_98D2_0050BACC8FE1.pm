# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 11 $
# $Date: 2006-11-06T23:14:31.537884Z $
# $Author: root(xternal) $
# $State$
# $xsa1$


use strict;


package Lib::ArcFourVariant;
# This is a simple streaming encryption / decryption object.
# It works by XORing the input byte stream by a pseudo-random stream,
# so applying the encryption sequence again decrypts the encypted data.
# This object can also be used directly as a pseudo-random generator.
# It is crucial to security to use a different salt for each encryption
# operation, especially if the same data may be encrypted at different times.
our $VERSION= '1.0';


use Lib::HandleOptions_F467BD47_CBA4_11D5_9920_C23CC971FBD2;
use Carp;


# Instance variables:
# Prefix is 'a4_'.
# $self->{a4_pool}->[0 .. 256 - 1].
# $self->{a4_i1}.
# $self->{a4_i2}.


# Creates a new object.
sub new {
   my $self= shift;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   $self->{a4_pool}= [];
   undef $self->{a4_i1};
   undef $self->{a4_i2};
   $self;
}


sub stir {
   my($self, $source)= @_;
   my($i, $k, $n, $p, $b);
   $k= $i= 0;
   $p= $self->{a4_pool};
   for ($n= 256 if ($n= $b= length $source) < 256; $n--; ) {
      $k= $b if $k == 0;
      $i
      = $i
      + ((unpack 'C', substr $source, --$k, 1) + 1) * ($p->[$i] + 1) % 257
      & 256 - 1
      ;
      ($p->[$n & 256 - 1], $p->[$i])= ($p->[$i], $p->[$n & 256 - 1]);
   }
}


sub preset {
   my $self= shift;
   my($i, $p);
   $p= $self->{a4_pool};
   for ($i= 256; $i--; ) {
      $p->[$i]= $i;
   }
   $self->{a4_i1}= $self->{a4_i2}= 0;
}


# Sets a random key, based on certain true-random sources
# and the data in $data if provided.
# This will initiate a non-repeatable pseudo-random sequence.
sub randomize {
   my($self, $data)= @_;
   $self->preset;
   $self->stir(pack 'C*', 1, 2, 3, 5, 7, 11, 13, 17);
   $self->stir($data) if defined $data;
   $self->stir(time . localtime);
}


# Creates a salt of the specified bit size.
# Bit size must be a multiple of 8 (defaults to 256 bits).
# Uses the current pseudo-random sequence for obtaining the salt.
# Normally randomize() will be called before this to set up a new sequence.
sub create_salt {
   my($self, $bitsize)= @_;
   $bitsize= defined $bitsize ? int $bitsize / 8 : 256 / 8;
   my(@s, @n, $i, $j);
   # Preset accumulation array to initial constant.
   $j= 13;
   for ($i= $bitsize; $i--; ) {
      $s[$i]= $j^= ($j + 1) * (
         (
            (1 << ($i & 8 - 1))
            + $i
            & (1 << 8) - 1
            ^ 1 << 8 - 1 - ($i & 8 - 1)
         )
         + 1
      )
      % 257
      & 256 - 1
      ;
   }
   # Accumulate.
   for ($i= 1 + int 256 / $bitsize; --$i >= 0; ) {
      $self->generate(\@n, $bitsize);
      for ($j= $bitsize; $j--; ) {
         $s[$j]^= ($n[$j] + 1) * ($s[$j] + 1) % 257 & 256 - 1;
      }
   }
   pack 'C*', @s;
}


# Uses key and salt to start a new crypto sequence.
# $key is an arbitrary-sized binary string.
# $salt should have been obtained from salt().
sub set_key {
   my($self, $key, $salt)= @_;
   $self->preset;
   $self->stir($salt);
   $self->stir($key);
   $self->stir($salt);
}


# Generate pseudo-random bytes.
# $string= $self->generate($count): Generate binary string.
# @array= $self->generate($count): Generate integer array value 0 .. 255.
# $self->generate(\$string): Fill existing string.
# $self->generate(\$string, $count): Fill only first $count characters.
# $self->generate(\@array): Fill existing integer array.
# $self->generate(\@array, $count): Set first $count entries of integer array.
sub generate {
   my($self, $count)= @_;
   my($v1, $v2, $dest, $i);
   my($i1, $i2, $pool)= ($self->{a4_i1}, $self->{a4_i2}, $self->{a4_pool});
   if (ref $count) {
      if (ref $count eq 'ARRAY') {
         # $self->generate(\@array [, $count]).
         ($dest, $count)= ($count, $_[2]);
         $count= @$dest unless defined $count;
         for ($i= 0; $i < $count; ++$i) {
            $i1= $i1 + 1 & 256 - 1;
            $i2-= 256 if ($i2+= $pool->[$i1]) >= 256;
            ($v2, $v1)= @{$pool}[$i2, $i1];
            @{$pool}[$i1, $i2]= ($v1, $v2);
            $dest->[$i]= $pool->[$v1 + $v2 & 256 - 1];
         }
      }
      else {
         # $self->generate(\$string [, $count]).
         ($dest, $count)= ($count, $_[2]);
         $count= length $$dest unless defined $count;
         for ($i= 0; $i < $count; ++$i) {
            $i1= $i1 + 1 & 256 - 1;
            $i2-= 256 if ($i2+= $pool->[$i1]) >= 256;
            ($v2, $v1)= @{$pool}[$i2, $i1];
            @{$pool}[$i1, $i2]= ($v1, $v2);
            substr($$dest, $i, 1)= pack 'C', $pool->[$v1 + $v2 & 256 - 1];
         }
      }
      ($self->{a4_i1}, $self->{a4_i2})= ($i1, $i2);
      return;
   }
   if (wantarray) {
      # @array= $self->generate($count).
      my(@array);
      $self->generate(\@array, $count);
      return @array;
   }
   # $string= $self->generate($count).
   $dest= pack 'x' x $count;
   $self->generate(\$dest);
   $dest;
}


# Encrypt or decrypt a string or array.
# $self->crypt($string): Return En/Decrypted string.
# $self->crypt(\$string): En/Decrypt all characters of $string.
# $self->crypt(\$string, $count): En/Decrypt only first $count characters.
# $self->crypt(\@array): En/Decrypt all characters of integer array.
# $self->crypt(\@array, $count): En/Decrypt only first $count elements.
sub crypt {
   my($self, $dest, $count)= @_;
   unless (ref $dest) {
      # $self->crypt($string).
      $self->crypt(\$dest);
      return $dest;
   }
   my($v1, $v2, $i);
   my($i1, $i2, $pool)= ($self->{a4_i1}, $self->{a4_i2}, $self->{a4_pool});
   if (ref $dest eq 'ARRAY') {
      # $self->crypt(\@array [, $count]).
      $count= @$dest unless defined $count;
      for ($i= 0; $i < $count; ++$i) {
         $i1= $i1 + 1 & 256 - 1;
         $i2-= 256 if ($i2+= $pool->[$i1]) >= 256;
         ($v2, $v1)= @{$pool}[$i2, $i1];
         @{$pool}[$i1, $i2]= ($v1, $v2);
         $dest->[$i]^= $pool->[$v1 + $v2 & 256 - 1];
      }
   }
   else {
      # $self->crypt(\$string [, $count]).
      $count= length $$dest unless defined $count;
      for ($i= 0; $i < $count; ++$i) {
         $i1= $i1 + 1 & 256 - 1;
         $i2-= 256 if ($i2+= $pool->[$i1]) >= 256;
         ($v2, $v1)= @{$pool}[$i2, $i1];
         @{$pool}[$i1, $i2]= ($v1, $v2);
         substr($$dest, $i, 1)= pack(
            'C',
            (unpack 'C', substr $$dest, $i, 1) ^ $pool->[$v1 + $v2 & 256 - 1]
         );
      }
   }
   ($self->{a4_i1}, $self->{a4_i2})= ($i1, $i2);
   return;
}


# Burn evidence in instance variables before releasing storage.
# This won't help too much in garbage-collected languages like PERL,
# but it is still better than doing nothing at all.
DESTROY {
   my $self= shift;
   my($p, $i);
   $p= $self->{a4_pool};
   for ($i= 256; $i--; ) {
      $p->[$i]= 0;
   }
   $self->{a4_i1}= $self->{a4_i2}= 0;
}


1;


__END__


use strict;
use Lib::ArcFourVariant_A519F072_D9E1_11D5_98D2_0050BACC8FE1;

my($a4, $salt, $s, $pwd, @s, $p);
$a4= new Lib::ArcFourVariant;
$a4->randomize;
$salt= $a4->create_salt;
# Random string.
$s= $a4->generate(10);
$p= $s;
@s= $a4->generate(10);
$p.= pack 'C*', @s;
$a4->generate(\$s);
$p.= $s;
$a4->generate(\$s, 10);
$p.= $s;
$a4->generate(\@s);
$p.= pack 'C*', @s;
$a4->generate(\@s, 10);
$p.= pack 'C*', @s;
# Encrypt.
$pwd= 'PASSWORD';
$a4->set_key($pwd, $salt);
$s= $a4->crypt($p);
$a4->crypt(\$s);
$a4->crypt(\$s, length $s);
@s= unpack 'C*', $s;
$a4->crypt(\@s);
$a4->crypt(\@s, scalar @s);
# Decrypt.
$a4->set_key($pwd, $salt);
$a4->crypt(\@s, scalar @s);
$a4->crypt(\@s);
$s= $a4->crypt(pack 'C*', @s);
$a4->crypt(\$s, length $s);
$a4->crypt(\$s);
die unless $s eq $p;
print "Test passed!";
