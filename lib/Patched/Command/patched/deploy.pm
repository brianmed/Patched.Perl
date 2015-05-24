package Patched::Command::patched::deploy;

use autodie;

use Mojo::Base 'Mojolicious::Command';

use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use Mojo::Date;
use Mojo::JSON 'encode_json';
use Mojo::Util qw(spurt sha1_sum);
use Time::HiRes;
use Net::SFTP::Foreign;
use File::Temp qw(tempfile);

use Patched::Globals;
use Patched::File;
use Patched::Bcrypt;
use Patched::Command;

has description => 'Deploy Patched';
has usage => sub { shift->extract_usage };

sub run {
    my ($self, @args) = @_;
    
    my ($args, $options) = ([], {});
    GetOptionsFromArray \@args,
      'host=s'   => \my $host,
      'user=s'   => \my $user,
      'pass=s'   => \my $pass,
      'port=s'   => \my $port,
      'method=s' => \my $method,
      'type=s'   => \my $type,
      'secret=s' => \my $secret,
      'config_dbi_user=s' => \my $dbi_user,
      'config_dbi_pass=s' => \my $dbi_pass,
      'boot'     => \my $boot;

    unless ($method && $method =~ m/^(sftp)$/i) {
        die("Please specify -method.\n");
    }

    unless ($host) {
        die("Please specify -host.\n");
    }

    my %args = (
        host => $host,
        autodie => 1,
    );

    $args{user} = $user if $user;
    $args{pass} = $pass if $pass;
    $args{port} = $port if $port;

    say("[sftp connect] $host");
    my $sftp = Net::SFTP::Foreign->new(%args);
    $sftp->die_on_error("Unable to establish SFTP connection: $host");

    say("[verify supported OS] $host");
    my $not_found = 0;
    $sftp->find("/etc/centos-release", on_error => sub { $not_found = 1 });
    if ($not_found) {
        die("We only support CentOS right now.\n");
    }

    my (undef, $release) = tempfile("patched_XXXXXX", TMPDIR => 1, UNLINK => 0);
    $sftp->get("/etc/centos-release", $release);

    my $file = Patched::File->new(path => $release);
    unless ($file->match("CentOS release 6")) {
        die("We only support CentOS 6 right now.\n");
    }

    my $InstallDir = $Patched::Globals::InstallDir;

    say("[sftp check previous install] $host");
    $not_found = 0;
    $sftp->find($InstallDir, on_error => sub { $not_found = 1 });
    unless ($not_found) {
        die("Install directory '$InstallDir' exists.\n");
    }

    say("[sftp mkpath] $InstallDir");
    $sftp->mkpath($InstallDir);

    my @t0 = @{[Time::HiRes::gettimeofday]};

    my $json = {
        secret => { current => sha1_sum("$t0[0].$t0[1]"), whence => $t0[0] },
        type => $type,
    };

    if ("minion" eq $type) {
        if (!$dbi_user || !$dbi_pass) {
            die("Need -config_dbi_user and -config_dbi_pass\n");
        }

        $json->{dbi_user} = $dbi_user;
        $json->{dbi_pass} = $dbi_pass;
    }

    my ($fh, $config) = tempfile("patched_XXXXXX", TMPDIR => 1);

    say("[spurt] JSONConfig");
    spurt(encode_json($json), $config);
    seek($fh, 0, 0);

    say("[sftp put] $InstallDir/config");
    $sftp->put($fh, "$InstallDir/config");

    unless ($boot) {
        return;
    }
}

1;

=encoding utf8

=head1 NAME

Patched::Command::patched::deploy - Deploy Patched

=head1 SYNOPSIS

  Usage: APPLICATION patched deploy [OPTIONS]

    ./patched.pl patched deploy

  Options:
    --host <name>     Hostname to deploy to
    --user <name>     Hostname to deploy to
    --pass <secret>   Hostname to deploy to
    --port <number>   Hostname to deploy to
    --method <type>   File transfer method [ssh]
    --type <mode>     Type of install [standalone|minion]
    --boot            Start Patched on boot

=head1 DESCRIPTION

L<Patched::Command::patched::deploy> deploy L<Patched>.

=head1 ATTRIBUTES

L<Patched::Command::patched::deploy> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $deploy->description;
  $deploy         = $deploy->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $deploy->usage;
  $deploy   = $deploy->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Patched::Command::patched::deploy> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $deploy->run(@ARGV);

Run this command.

=cut

