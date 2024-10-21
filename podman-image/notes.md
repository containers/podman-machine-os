/etc/chrony.d/50-podman-makestep.conf
/etc/chrony.conf
/etc/profile.d/docker-host.sh
/etc/containers/registries.conf.d/999-podman-machine.conf
/etc/sysctl.d/10-inotify-instances.conf
/var/lib/systemd/linger/core

	// Enables automatic login on the console;
	// there's no security concerns here, and this makes debugging easier.
	// xref https://docs.fedoraproject.org/en-US/fedora-coreos/tutorial-autologin/
/etc/systemd/system/serial-getty@.service.d/10-autologin.conf
/etc/systemd/system/getty@.service.d/10-autologin.conf



// Set delegate.conf so cpu,io subsystem is delegated to non-root users as well for cgroupv2
// by default
/etc/systemd/system/user@.service.d/delegate.conf

Directories that need creating

	// The directory is used by envset-fwcfg.service
	// for propagating environment variables that got
	// from a host
/etc/containers/registries.conf.d
/etc/systemd/system.conf.d
/etc/environment.d
	// Issue #11489: make sure that we can inject a custom registries.conf
	// file on the system level to force a single search registry.
	// The remote client does not yet support prompting for short-name
	// resolution, so we enforce a single search registry (i.e., docker.io)
	// as a workaround.
    /etc/containers/registries.conf.d

# SystemD services
podman.socket (enabled)
zincati (disabled) ?
