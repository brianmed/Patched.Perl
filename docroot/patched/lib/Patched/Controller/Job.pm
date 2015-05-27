package Patched::Controller::Job;

use Mojo::Base 'Mojolicious::Controller';

use Patched::Globals;
use Patched::Command;
use Patched::File;

sub run {
    my $c = shift;

    $c->inactivity_timeout(3600);

    my $code = $c->req->json->{code};
    my $name = $c->req->json->{name};
    my $script = $Patched::Globals::Preamble . "\n\n### $name\n\n" .$code;
    my $file = Patched::File->tmp({ contents => $script, suffix => "pl"});
    $c->app->log->debug("file: $file");

    my $cmd = Patched::Command->new(cmd => $Patched::Globals::Perl, args => $file, timeout => 3600)->run;

    return($c->render(json => {success => $cmd->success}));
}

1;
