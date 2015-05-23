package Patched;

use Mojo::Base 'Mojolicious';

use Patched::Globals;

sub startup {
    my $self = shift;
    
    my $InstallDir = $Patched::Globals::InstallDir;

    my $config = $self->plugin(JSONConfig => {file => "$InstallDir/config"});
    $self->plugin('Patched');

    if ($$config{type} && "minion" eq $$config{type}) {
        $self->plugin(Minion => {Pg => "postgresql://$$config{dbi_user}:$$config{dbi_pass}\@127.0.0.1/patched_jobs"});
    }

    my $r = $self->routes;
    
    $r->get('/')->to(controller => 'Index', action => 'slash');
}

1;
