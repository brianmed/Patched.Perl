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
      'e|enqueue=s'  => \my $enqueue,
      'f|file'       => \my $file;
    
    # Enqueue
    if ($enqueue) {
        my $bytes = encode_json(slurp($file));
        $self->app->minion->enqueue($enqueue, $bytes, $options)
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
    -e, --enqueue <name>      New job to be enqueued
    -l, --file <filename>     Filename to load

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
