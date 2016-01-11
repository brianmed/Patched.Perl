#!/usr/bin/env perl

#######################################################################
# $ perl invoke.pl patched deploy
#######################################################################

use lib qw(lib);

use Patched::CommandLine;

plugin qw(Patched);

# May need to groupinstall Development\ Tools
# May need POSTGRES_HOME set

app->start;
