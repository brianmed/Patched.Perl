package Patched::Packages;

use Mojo::Base -strict;

use autodie;
use Moose;
use Carp;

use Patched::Command;

use experimental qw(signatures);

sub have_updates ($this) {
    my $yum = Patched::Command->find("yum") or croak("Unable to find yum command");

    my $cmd = Patched::Command->new(cmd => $yum, args => ["check-update"], autodie => 0, timeout => 120)->run;
    
    my $child_error = $cmd->child_error >> 8;
    if (100 == $child_error) {
        return 1;
    }
    else {
        return 0;
    }
}

sub update ($this) {
    my $yum = Patched::Command->find("yum") or croak("Unable to find yum command");

    my $cmd = Patched::Command->new(cmd => $yum, args => ["-y", "update"], autodie => 1, timeout => 3600)->run;

    Patched::Log->info("Updated packages via yum");
    Patched::Log->info(${ $cmd->stdout });
    Patched::Log->info(${ $cmd->stderr }) if ${ $cmd->stderr };

    return 1;
}

sub install ($this, $group) {
    my $yum = Patched::Command->find("yum") or croak("Unable to find yum command");

    my $cmd = Patched::Command->new(cmd => $yum, args => ["-y", "groupinstall", $group], autodie => 1, timeout => 3600)->run;

    Patched::Log->info("Installed packages via yum");
    Patched::Log->info(${ $cmd->stdout });
    Patched::Log->info(${ $cmd->stderr }) if ${ $cmd->stderr };

    return 1;
}

1;
