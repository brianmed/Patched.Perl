package Patched::Globals;

our $InstallDir = "/opt/Patched";
our $Perl = "/opt/Patched/perl";

our $Preamble = qq(
    use lib qw(/opt/Patched/lib);
    
    use Mojo::Base -strict;

    use Patched::Bcrypt;
    use Patched::Command;
    use Patched::Environment;
    use Patched::File;
    use Patched::Globals;
    use Patched::User;

    our \$Distro = Patched::Environment->distribution;
    our \$DistroVer = Patched::Environment->version;

);

1;
