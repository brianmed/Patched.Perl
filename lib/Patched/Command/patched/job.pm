package Patched::Command::patched::job;

use Mojo::Base 'Mojolicious::Command';

use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use Mojo::Date;
use Mojo::JSON 'encode_json';
use Mojo::Util qw(slurp);

has description => 'Manage Patched jobs';
has usage => sub { shift->extract_usage };

sub run {
    my ($self, @args) = @_;
    
    my ($args, $options) = ([], {});
    GetOptionsFromArray \@args,
      'run=s'      => \my $run,
      'enqueue=s'  => \my $enqueue,
      'api_key=s'  => \my $api_key,
      'script=s'     => \my $script;
    
    if ($enqueue && $run) {
        $self->usage;
        die("Please don't specify -run and -enqueue.\n");
    }

    if ($enqueue) {
        my $bytes = encode_json(slurp($script));
        $self->app->minion->enqueue($enqueue, $bytes, $options)
    }

    if ($run) {
        use Mojo::UserAgent;
        use Mojo::URL;

        my $ua = Mojo::UserAgent->new;

        my $url = Mojo::URL->new("http://$run:6000/api/v1/job/run");
        my $tx = $ua->post($url, => json => { code => slurp($script), api_key => $api_key });

        if ($tx->success) {
            if ($tx->res->json->{success}) {
                say("Job was successful");
            }
            else {
                say("Job fail: " . $tx->res->json->{data}{message});
            }
        }
        else {
            say(sprintf("Error [%s]: %s", $tx->error->{code} // "0", $tx->error->{message}));
        }
    }
}

1;

=encoding utf8

=head1 NAME

Patched::Command::patched::job - Patched job command

=head1 SYNOPSIS

  Usage: APPLICATION patched job [OPTIONS]

    ./patched.pl patched job -e foo -f foo.pl

  Options:
    --run <host>          Host to run job on
    --api_key <key>       Password for remote agent
    --enqueue <name>      New job to be enqueued
    --script <filename>   Filename to load

=head1 DESCRIPTION

L<Patched::Command::patched::job> manages L<Patched> jobs.

=head1 ATTRIBUTES

L<Patched::Command::patched::job> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $job->description;
  $job            = $job->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $job->usage;
  $job      = $job->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Patched::Command::patched::job> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $job->run(@ARGV);

Run this command.

=cut
