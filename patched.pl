#!/opt/perl

use Mojolicious::Lite;

if (@ARGV && 2 == @ARGV && "$ARGV[0] $ARGV[1]" =~ m/^patched\s+install$/i) {
    plugin qw(Patched);

    app->start(@ARGV);

    exit;
}

if (!-d "/opt/Patched" || !-f "/opt/Patched/config") {
    say("Please run '$0 patched install'");

    exit;
}

my $config = plugin JSONConfig => {file => "/opt/Patched/config"};
plugin Minion => {Pg => "postgresql://$ENV{DBI_USER}:$ENV{DBI_PASS}\@127.0.0.1/patched_jobs"};
plugin qw(Patched);

get '/' => sub {
    my $c = shift;

    $c->render(data => 'Hello');
};

app->secrets([$config->{secret}]);
app->start;
