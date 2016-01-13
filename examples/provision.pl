use Patched::Minimal;

packages->install("Development Tools");

if (packages->have_updates) {
    packages->update;

    localhost->reboot;
}
