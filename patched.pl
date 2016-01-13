#!/usr/bin/env perl

#######################################################################
# $ perl invoke.pl patched deploy
#######################################################################

use lib qw(lib);

use Patched::CommandLine;

plugin qw(Patched);

app->start;
