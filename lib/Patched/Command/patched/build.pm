package Patched::Command::patched::build;

use autodie;

use Mojo::Base 'Mojolicious::Command';

use Getopt::Long qw(GetOptionsFromArray :config no_auto_abbrev no_ignore_case);
use Mojo::Date;
use Mojo::JSON 'encode_json';
use Mojo::Util qw(spurt sha1_sum);
use Time::HiRes;
use Net::OpenSSH;
use IO::Handle;
use Fcntl qw(:DEFAULT);

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
      'port=s'   => \my $port;

    unless ($host) {
        say $self->usage;
        die("Please specify -host.\n");
    }

    $port //= 22;
    
    if (-f "build/CentOS-6-perl-5.20.3.tar.gz") {
        die("build/CentOS-6-perl-5.20.3.tar.gz already exists\n");
    }

    my @t0 = @{[Time::HiRes::gettimeofday]};

    my $std = sprintf("%d.%06d", @t0);
    my $stdout = sprintf("%d.%06d.out.log", @t0);
    my $stderr = sprintf("%d.%06d.err.log", @t0);

    sysopen(my $stdout_fh, "log/$stdout", O_RDWR|O_CREAT|O_EXCL);
    $stdout_fh->autoflush(1);

    sysopen(my $stderr_fh, "log/$stderr", O_RDWR|O_CREAT|O_EXCL);
    $stderr_fh->autoflush(1);

    say("[ssh2 connect] $host");
    my $ssh2 = Net::OpenSSH->new(host => $host, user => $user, password => $pass, port => $port, master_opts => [-o => "StrictHostKeyChecking=no"]);

    say("[verify supported OS] $host");
    my $system = $ssh2->system({timeout => 30, stdin_discard => 1, stdout_discard => 1}, "test -f /etc/centos-release && grep 'CentOS release 6' /etc/centos-release") or die("verify failed: " . $ssh2->error);
    unless ($system) {
        die("We only support CentOS right now.\n");
    }

    my $sftp = $ssh2->sftp;
    my $InstallDir = $Patched::Globals::InstallDir;

    say("[sftp check previous install] $host");
    my $not_found = 0;
    $sftp->find($InstallDir, on_error => sub { $not_found = 1 });
    unless ($not_found) {
        die("Install directory '$InstallDir' exists.\n");
    }

    say("[sftp mkpath] $InstallDir");
    $sftp->mkpath($InstallDir) or die("sftp error: " . $sftp->error);

    say("[sftp mkpath] $InstallDir/log");
    $sftp->mkpath("$InstallDir/log") or die("sftp error: " . $sftp->error);

    say("[sftp mkpath] $InstallDir/build");
    $sftp->mkpath("$InstallDir/build") or die("sftp error: " . $sftp->error);

    say("[sftp put] $InstallDir/build/perl-5.20.3.tar.gz");
    $sftp->put("build/perl-5.20.3.tar.gz", "$InstallDir/build/perl-5.20.3.tar.gz") or die("sftp error: " . $sftp->error);

    say("[sftp put] build/cpanm");
    $sftp->put("build/cpanm", "$InstallDir/build/cpanm") or die("sftp error: " . $sftp->error);

    say("[sftp put] build/perl-build");
    $sftp->put("build/perl-build", "$InstallDir/build/perl-build") or die("sftp error: " . $sftp->error);

    say("[sftp put] cpanfile");
    $sftp->put("cpanfile", "$InstallDir/build/cpanfile") or die("sftp error: " . $sftp->error);

    say("[ssh2 system --> log/$std] cd $InstallDir/build && /usr/bin/perl perl-build ./perl-5.20.3.tar.gz /opt/Patched/perl-5.20.3");
    $system = $ssh2->system({timeout => 3600, stdin_discard => 1, stderr_fh => $stderr_fh, stdout_fh => $stdout_fh}, "cd $InstallDir/build && /usr/bin/perl perl-build ./perl-5.20.3.tar.gz /opt/Patched/perl-5.20.3") or die("sftp error: " . $ssh2->error);
    unless ($system) {
        die("Unable to build perl-5.20.3\n");
    }
    say($stdout_fh "-=================================");
    say($stderr_fh "=================================-");

    say("[ssh2 system --> log/$std] cd $InstallDir/build && /opt/Patched/perl-5.20.3/bin/perl /opt/Patched/build/cpanm App::cpanminus");
    $system = $ssh2->system({timeout => 3600, stdin_discard => 1, stderr_fh => $stderr_fh, stdout_fh => $stdout_fh}, "cd $InstallDir/build && /opt/Patched/perl-5.20.3/bin/perl /opt/Patched/build/cpanm App::cpanminus") or die("sftp error: " . $ssh2->error);
    unless ($system) {
        die("Unable to install App::cpanminus\n");
    }
    say($stdout_fh "-=================================");
    say($stderr_fh "=================================-");

    say("[ssh2 system --> log/$std] cd $InstallDir/build && /opt/Patched/perl-5.20.3/bin/cpanm --notest --installdeps .");
    $system = $ssh2->system({timeout => 3600, stdin_discard => 1, stderr_fh => $stderr_fh, stdout_fh => $stdout_fh}, "cd $InstallDir/build && /opt/Patched/perl-5.20.3/bin/cpanm --notest --installdeps .") or die("sftp error: " . $ssh2->error);
    unless ($system) {
        die("Unable to cpanm --notest --installdeps .\n");
    }
    say($stdout_fh "-=================================");
    say($stderr_fh "=================================-");

    say("[ssh2 system --> log/$std] cd $InstallDir && tar -zcvf build/CentOS-6-perl-5.20.3.tar.gz perl-5.20.3");
    $system = $ssh2->system({timeout => 3600, stdin_discard => 1, stderr_fh => $stderr_fh, stdout_fh => $stdout_fh}, "cd $InstallDir && tar -zcvf build/CentOS-6-perl-5.20.3.tar.gz perl-5.20.3") or die("sftp error: " . $ssh2->error);
    unless ($system) {
        die("Unable to tar up CentOS-6-perl-5.20.3.tar.gz\n");
    }

    close($stdout_fh);
    close($stderr_fh);

    say("[sftp get] $InstallDir/build/CentOS-6-perl-5.20.3.tar.gz");
    $sftp->get("$InstallDir/build/CentOS-6-perl-5.20.3.tar.gz", "build/CentOS-6-perl-5.20.3.tar.gz") or die("sftp error: " . $sftp->error);

    say("[SUCCESS built]");
}

1;

=encoding utf8

=head1 NAME

Patched::Command::patched::build - Build Patched

=head1 SYNOPSIS

  Usage: APPLICATION patched build [OPTIONS]

    ./patched.pl patched build

  Options:
    --host <name>      Hostname to build onto
    --user <user>      Username for ssh
    --pass <secret>    Password for ssh
    --port <number>    Port for ssh

=head1 DESCRIPTION

L<Patched::Command::patched::build> build L<Patched>.

=head1 ATTRIBUTES

L<Patched::Command::patched::build> inherits all attributes from
L<Mojolicious::Command> and implements the following new ones.

=head2 description

  my $description = $build->description;
  $build          = $build->description('Foo');

Short description of this command, used for the command list.

=head2 usage

  my $usage = $build->usage;
  $build    = $build->usage('Foo');

Usage information for this command, used for the help screen.

=head1 METHODS

L<Patched::Command::patched::build> inherits all methods from
L<Mojolicious::Command> and implements the following new ones.

=head2 run

  $build->run(@ARGV);

Run this command.

=cut


