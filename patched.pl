#!/opt/Patched/perl

use Mojolicious::Lite;
use Patched::Globals;

if (@ARGV && 2 == @ARGV && "$ARGV[0] $ARGV[1]" =~ m/^patched\s+deploy$/i) {
    plugin qw(Patched);

    app->start(@ARGV);

    exit;
}

my $InstallDir = $Patched::Globals::InstallDir;

if (!-d $InstallDir || !-f "$InstallDir/config") {
    say("Please run '$0 patched deploy'");

    exit;
}

my $config = plugin JSONConfig => {file => "$InstallDir/config"};

if ("minion" eq $$config{type}) {
    plugin Minion => {Pg => "postgresql://$$config{dbi_user}:$$config{dbi_pass}\@127.0.0.1/patched_jobs"};
}

plugin qw(Patched);

get '/' => sub {
    my $c = shift;

    $c->render(data => 'Hello');
};

Patched::File::spurt($$, "$InstallDir/pids/agent.pid");

END {
    unlink("$InstallDir/pids/agent.pid");
}

app->secrets([$config->{secret}]);
app->start;
