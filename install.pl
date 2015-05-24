#!/usr/bin/env perl

#######################################################################
# $ perl install.pl patched deploy
#######################################################################

use lib qw(lib);

use Mojolicious::Lite;
use Patched::Globals;

plugin qw(Patched);

# May need to groupinstall Development\ Tools
# May need POSTGRES_HOME set

unless(@ARGV) {
    my $InstallDir = $Patched::Globals::InstallDir;
    if (!-d $InstallDir || !-f "$InstallDir/config") {
        say("Please run '$0 patched deploy'");

        exit;
    }
}

app->start;
