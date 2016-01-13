use Patched::Minimal;

packages->install("Development Tools");

my $perl_path = "/usr/local/perl-5.20.3";

unless (-d $perl_path) {
    Patched::Log->info("Perl::Build->install_from_cpan('5.20.3')");

    require Perl::Build;

    Perl::Build->install_from_cpan('5.20.3' => (dst_path  => $perl_path));
};

if (packages->have_updates) {
    packages->update;

    localhost->reboot;
}
