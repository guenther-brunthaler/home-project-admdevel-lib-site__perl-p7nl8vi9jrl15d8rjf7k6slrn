# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision: 2673 $
# $Date: 2006-08-28T21:08:25.327061Z $
# $Author: gb $
# $State$
# $xsa1$


use strict;


package Lib;


use Carp;


# Splits a filename in path (empty or trailing slash),
# prefix and properly formatted UUID and extension (empty or leading dot)
sub SplitFilenameUUID {
   my($fn)= shift;
   unless (
      $fn =~ /
         ^
         # Optional path as $1.
         (.*[\/\\:])?
         # Optional prefix as $2.
         ([^\/\\.]*?)?
         # Optional underscores.
         _*
         # UUID.
         (?:
            # Only hex digits as $3.
            ([\dA-F]{32})
            # Dash or underscore separated hex digits as $4.
            | (
               [\dA-F]{8} # First number.
               ([-_]) # Selected separator as $5.
               (?:[\dA-F]{4}\5){3} # Three more numbers.
               [\dA-F]{12} # Last number.
            )
         )
         # Optional extension as $6.
         (\..+?)?
         $
      /ix
   ) {
      croak "Improper filename format of '$fn':\n"
      . "$5Missing a valid UUID at the end of the file name"
      ;
   }
   my($path, $prefix, $uuid, $ext)= ($1, $2, $3, $6);
   unless (defined $uuid) {
      $uuid= $4;
      $uuid =~ tr/-_//d;
   }
   $uuid =~ s/(.{8})(.{4})(.{4})(.{4})(.{12})/\U$1-$2-$3-$4-$5/
   or croak "invalid UUID format '$uuid'"
   ;
   map {defined() ? $_ : ''} ($path, $prefix, $uuid, $ext);
}


1;
