package Patched::Command::job;

use Mojo::Base 'Mojolicious::Command';

use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use Mojo::Date;
use Mojo::JSON 'encode_json';
use Mojo::Util qw(slurp);
use Net::OpenSSH;
use File::Basename qw(basename);

use Patched::File;
use Patched::Globals;

has description => 'Manage Patched jobs';
has usage => sub { shift->extract_usage };

sub run {
    my ($self, @args) = @_;
    
    my ($args, $options) = ([], {});
    GetOptionsFromArray \@args,
      'run=s'      => \my $run,
      'user=s'   => \my $user,
      'pass=s'   => \my $pass,
      'port=s'   => \my $port,
      'conf=s'   => \my $conf,
      'verbose'   => \my $verbose,
      'script=s'   => \my $script;

    $port //= 22;
    
    # "standalone mode"
    if ($run) {
        say("[ssh2 connect - $run]");
        my $ssh2 = Net::OpenSSH->new(host => $run, user => $user, password => $pass, port => $port, master_opts => [-o => "StrictHostKeyChecking=no"]);

        say("[verify supported OS]");
        my $system = $ssh2->system({timeout => 30, stdin_discard => 1, stdout_discard => 1}, "test -f /etc/centos-release && grep 'CentOS release 6' /etc/centos-release") or die("verify failed: " . $ssh2->error);
        unless ($system) {
            die("We only support CentOS right now.\n");
        }

        my $sftp = $ssh2->sftp;

        say("[sftp check previous install]");
        my $InstallDir = $Patched::Globals::InstallDir;
        my $not_found = 0;
        $sftp->find($InstallDir, on_error => sub { $not_found = 1 });
        if ($not_found) {
            die("Install directory '$InstallDir' doesn't exists.\n");
        }

        say("[run $script]");
        my $code = Patched::File->new(path => $script)->slurp;

        my $contents = $Patched::Globals::Preamble . "\n\n### $script\n\n" . $code;

        my $remote_dir = $ssh2->capture({timeout => 3600}, "mktemp -d") or die("system failed: " . $ssh2->error);
        chomp($remote_dir);

        my $remote_file = sprintf("%s/%s", $remote_dir, basename($script));

        say("[put $script -> $remote_file]");
        $sftp->put_content($contents, $remote_file) or die("sftp error: " . $sftp->error);

        if ($conf) {
            my $file = basename($conf);

            my $sftp = $ssh2->sftp;

            say("[put $conf -> $remote_dir/$file]");
            $sftp->put($conf, "$remote_dir/$file") or die("sftp error: " . $sftp->error);
        }

        say("[run /opt/Patched/perl $remote_file]");
        my $out = $ssh2->capture({timeout => 3600, stdin_discard => 1, stderr_to_stdout => 1}, "/opt/Patched/perl $remote_file");
        die(sprintf("ssh2 capture error: %s\n", $ssh2->error)) if $ssh2->error;
        
        say($out) if $verbose;
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
