package Patched::Log;

use Mojo::Base -strict;

use autodie;
use Moose;
use Carp;
use File::Path qw(make_path);
use Fcntl qw(:flock SEEK_END);
use Time::HiRes;

use Patched::Globals;

use experimental qw(signatures);

my $singleton;

has 'path' => (is => 'rw', isa => 'Str');

sub info ($class, $line) {
    $class->new unless defined $singleton;

    open(my $info, ">>", $singleton->path . "/" . "info.log");

    lock($info);
    print($info sprintf("%s %s\n", scalar(localtime), $line));
    unlock($info);
}

sub lock ($fh) {
    flock($fh, LOCK_EX) or die "Cannot lock mailbox - $!\n";

    # and, in case someone appended while we were waiting...
    seek($fh, 0, SEEK_END) or die "Cannot seek - $!\n";
}

sub unlock ($fh) {
    flock($fh, LOCK_UN) or die "Cannot unlock mailbox - $!\n";
}

# to protect against people using new() instead of instance()
around 'new' => sub {
    my $orig = shift;
    my $self = shift;

    return $singleton //= $self->$orig(@_)->initialize;
};

sub initialize ($this) {
    defined $singleton and croak __PACKAGE__ . ' singleton has already been instanciated'; 

    my @t0 = @{[Time::HiRes::gettimeofday]};

    my $dir = "$Patched::Globals::InstallDir/log/$t0[0].$t0[1]";
    
    make_path($dir);
    $this->path($dir);

    return $this;
}

1;
