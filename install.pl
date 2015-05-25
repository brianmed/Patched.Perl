#!/usr/bin/env perl

#######################################################################
# $ perl install.pl patched deploy
#######################################################################

use lib qw(lib);

use Mojolicious::Lite;

plugin qw(Patched);

# May need to groupinstall Development\ Tools
# May need POSTGRES_HOME set

app->start;
