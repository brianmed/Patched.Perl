package Patched::Controller::Job;

use Mojo::Base 'Mojolicious::Controller';

use Patched::Globals;
use Patched::Command;
use Patched::File;

sub run {
    my $c = shift;

    $c->inactivity_timeout(300);

    my $code = $c->req->json->{code};
    my $script = $Patched::Globals::Preamble . $code;
    my $file = Patched::File->tmp({ contents => $script});
    $c->app->log->debug("file: $file");

    my $cmd = Patched::Command->new(cmd => $Patched::Globals::Perl, args => $file)->run;

    return($c->render(json => {success => $cmd->success}));
}

1;
