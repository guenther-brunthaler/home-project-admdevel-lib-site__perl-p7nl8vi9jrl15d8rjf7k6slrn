# $xsa1={FBF02760-95CF-11D3-BD96-0040C72500FD}$
# $RCSfile$
# $Revision$
# $Date$
# $Author$
# $State$
# $xsa1$


use strict;


package Lib::TOOLS::AppSettings;
our $VERSION= '1.0';


use Carp;
use Win32::TieRegistry 0.20;
use Lib::StringConv_8AEE1C21_CBA0_11D5_9920_C23CC971FBD2;


=head1 NAME

Lib::TOOLS::AppSettings - Class for maintaining sets of
permanent application settings.

=head1 DESCRIPTION

This class provides several helper functions to aid in locating,
storing and retrieving application-specific settings.

=head1 METHODS

=cut


# Instance variables (hash key prefix is 'as22_'):
#
# $self: An instance of the AppSettings class.
# $self->{as22_settings}->{$GUID}: exists if $GUID is used
# $self->{as22_settings}->{$GUID}->{var}
# $self->{as22_settings}->{$GUID}->{class}
# $self->{as22_settings}->{$rkeycu}: Windows only:
#                                    key below HKEY_CURRENT_USER
# $self->{as22_settings}->{$rkeylm}: Windows only:
#                                    key below HKEY_LOCAL_MACHINE
# $self->{as22_company_id}.
# $self->{as22_application_id}.


=head2 CONSTRUCTOR new

            use Lib::TOOLS::AppSettings_8AEE1C22_CBA0_11D5_9920_C23CC971FBD2;
            $appid= 'MyApp {E550B5E0-0CA6-11D5-97D7-0050BACC8FE1}';
            $settings= Lib::TOOLS::AppSettings->new($appid);

Constructs and returns a new C<AppSettings> object that refers to
settings of the application C<$appid>.

=cut
sub new {
   my($self, $appid, $companyid)= @_;
   croak "app-id required" unless $appid;
   $companyid= 'Guenther Brunthaler EDV-Dienstleistungen' unless $companyid;
   $self= bless {} if !ref $self || ref $self eq __PACKAGE__;
   $self->{as22_company_id}= $companyid;
   $self->{as22_application_id}= $appid;
   {
      $lm= new Win32::TieRegistry 'LMachine'
      and $cu= new Win32::TieRegistry 'CUser'
      or croak "Can't access registry"
      ;
      $Registry->Delimiter('/');
      # Manufacturer key name.
      $appkm= 'Günther Brunthaler {CD32E710-F94F-11D4-980B-0000F831AADF}/';
      # Application subkey name.
      $appku= 'Camera Sorter {3C32E050-F94F-11D4-980B-0000F831AADF}/';
      $Registry->{'LMachine/SOFTWARE/'}= {$appkm => {$appku => {}}};
      $Registry->{'CUser/SOFTWARE/'}= {$appkm => {$appku => {}}};
      # Application keys for user and machine.
      ($appku, $appkm)= (
         $Registry->{"CUser/SOFTWARE/$appkm$appku"},
         $Registry->{"LMachine/SOFTWARE/$appkm$appku"}
      );
      $self->{as22_settings}->{$rkeycu}= $cu;
      $self->{as22_settings}->{$rkeylm}= $lm;
   }
   $self;
}


=head2 METHOD use

            $settings->use(
               {
                  qw"-guid {16D23124-0CAE-11D5-97D7-0050BACC8FE1}", -var => \$setting1
               },
               {
                  qw"-guid {55873121-0CAE-11D5-97D7-0050BACC8FE1}", -var => \$setting2
               }
            );

Define which permanent settings are used in this application.

=cut
sub use {
   my($self)= shift;
   my($setting, $g);
   $self->{as22_settings}= {};
   while ($setting= shift) {
      croak "guid required" unless $g= $setting->{-guid};
      $g= Lib::StringConv::Str2GUID($g);
      foreach (qw[var class]) {
         if (exists $setting->{"-$_"}) {
            $self->{as22_settings}->{$g}->{$_}= $setting->{"-$_"};
         }
      }
   }
}


=head2 METHOD repository_get

Get a value from the repository of class I<$class>
using the relative name I<$name>.

=cut
sub repository_get {
   my($self, $class, $name);
}


=head2 METHOD repository_set

Set a value to the repository of class I<$class>
using the relative name I<$name>.

=cut
sub repository_Set {
   my($self, $class, $name);
}


=head2 METHOD reset

Removes the settings file name and resets all variables to C<undef>.

=cut
sub reset {
   my($self, $wnd)= @_;
}


=head2 METHOD merge

Show an open file dialog and let the user select a setting file,
then load the settings overwriting any settings that may already exist.

=cut
sub merge {
   my($self, $wnd)= @_;
}


=head2 METHOD load

Show an open file dialog and let the user select a setting file,
then load the settings replacing all settings that may already exist.

=cut
sub load {
   my($self, $wnd)= @_;
   $self->reset($wnd);
   $self->merge($wnd);
}


=head2 METHOD save

Save the settings to the current settings file.

Shows a save file dialog and let the user select a current setting file
for saving if no such current settings file has been specified yet.

=cut
sub save {
   my($self, $wnd)= @_;
}


=head2 METHOD save_as

Show a save file dialog and let the user select a setting file for saving,
then save the settings.

=cut
sub save_as {
   my($self, $wnd)= @_;
   $self->save($wnd);
}


=head2 METHOD add_menu

            $mb= $wnd->Menu qw(-type menubar);
            $settings->add_menu($wnd, $mb->Cascade qw(-label File -tearoff no));
            $wnd->configure(-menu => $mb);

Adds menu commands to a given C<cascade> object that will call the
methods C<reset>, C<load>, C<save> and C<save_as>, respectively.

=cut
sub add_menu {
   my($self, $wnd, $cascade)= @_;
   $cascade->command(
      -label => 'New',
      -command => [sub {shift->reset(@_)}, $self, $wnd]
   );
   $cascade->command(
      -label => 'Open...',
      -command => [sub {shift->load(@_)}, $self, $wnd]
   );
   $cascade->command(
      -label => 'Save',
      -command => [sub {shift->save(@_)}, $self, $wnd]
   );
   $cascade->command(
      -label => 'Save As...',
      -command => [sub {shift->save_as(@_)}, $self, $wnd]
   );
}


=head2 METHOD fetch

Fetches the current values of the settings used in the application
into the associated variables.

=cut
sub fetch {
   my($self)= @_;
}


1;


__END__


=head1 NOTES

=head2 NOTES - CONSTRUCTOR new

            use Lib::TOOLS::AppSettings_8AEE1C22_CBA0_11D5_9920_C23CC971FBD2;
            $appid= 'MyApp {E550B5E0-0CA6-11D5-97D7-0050BACC8FE1}';
            $companyid= 'Guenther Brunthaler EDV-Dienstleistungen';
            $settings= Lib::TOOLS::AppSettings->new($appid, $companyid);

Constructs and returns a new C<AppSettings> object that refers to
settings of the application C<$appid> of company C<$companyid>.

If C<$companyid> is not specified, 'Guenther Brunthaler EDV-Dienstleistungen'
is used by default.

Both IDs - at least when combined together - must be unique to the
application in time and space, so it may be a good idea to include
a GUID or UUID as part of the name of at least one of the IDs.

That way there cannot be a name collisions under any circumstances.

=head2 NOTES - METHOD use

The only parameter is a list of option hash references, one hash per setting.

The hashes support the followin keys:

=over 4

=item -guid

The GUID that uniquely defines the meaning and format of the settings contents,
even across different applications.

=item -class

C<user> means privately to the current user. C<local> means locally to
the current machine, C<domain> means shared in the current network domain,
<project> means this setting should be stored in a project file.

If not specified, defaults to C<project>.

=item -var

This specifies a reference of the variable to obtain the current contents
of the setting.

=back
