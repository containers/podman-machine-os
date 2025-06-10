package verify

import (
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"testing"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
)

func TestMain(m *testing.M) {
	os.Exit(m.Run())
}

const (
	defaultDiskSize uint = 11
)

var (
	tmpDir         = os.TempDir()
	podmanBinary   string
	err            error
	imagePath      string
	vmTestProvider string
)

var _ = BeforeSuite(func() {
	podmanBinary, err = getPodmanBinary()
	Expect(err).ToNot(HaveOccurred(), "failed to find podman binary")
	GinkgoWriter.Printf("Using podman binary: %s\n", podmanBinary)
	if value, ok := os.LookupEnv("TMPDIR"); !ok {
		tmpDir = value
	}

	value, ok := os.LookupEnv("MACHINE_IMAGE_PATH")
	if !ok {
		Fail("unable to find image path")
	}
	imagePath = value

	cmdLine := []string{"machine", "info", "--format", "{{.Host.VMType}}"}
	session, err := runSystemCommand(podmanBinary, cmdLine, defaultTimeout, true)
	Expect(err).ToNot(HaveOccurred(), "get machine provider")
	vmTestProvider = session.outputToString()
	GinkgoWriter.Printf("Using Vm provider: %s\n", vmTestProvider)
})

func skipIfVmtype(vmType string, message string) {
	if vmTestProvider == vmType {
		Skip(message)
	}
}

func skipIfNotVmtype(vmType string, message string) {
	if vmTestProvider != vmType {
		Skip(message)
	}
}

const (
	QemuVirt    = "qemu"
	WSLVirt     = "wsl"
	AppleHvVirt = "applehv"
	HyperVVirt  = "hyperv"
	LibKrun     = "libkrun"
)

// TestLibpod ginkgo master function
func TestMachine(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Podman Machine tests")
}

func setup() (string, *imageTestBuilder) {
	homeDir, err := os.MkdirTemp(tmpDir, "podman_test")
	if err != nil {
		Fail(fmt.Sprintf("failed to create home directory: %q", err))
	}
	if err := os.MkdirAll(filepath.Join(homeDir, ".ssh"), 0700); err != nil {
		Fail(fmt.Sprintf("failed to create ssh dir: %q", err))
	}
	sshConfig, err := os.Create(filepath.Join(homeDir, ".ssh", "config"))
	if err != nil {
		Fail(fmt.Sprintf("failed to create ssh config: %q", err))
	}
	if _, err := sshConfig.WriteString("IdentitiesOnly=yes"); err != nil {
		Fail(fmt.Sprintf("failed to write ssh config: %q", err))
	}
	if err := sshConfig.Close(); err != nil {
		Fail(fmt.Sprintf("unable to close ssh config file descriptor: %q", err))
	}
	if err := os.Setenv("HOME", homeDir); err != nil {
		Fail("failed to set home dir")
	}
	if runtime.GOOS == "windows" {
		if err := os.Setenv("USERPROFILE", homeDir); err != nil {
			Fail("unable to set home dir on windows")
		}
	}
	if err := os.Setenv("XDG_RUNTIME_DIR", homeDir); err != nil {
		Fail("failed to set xdg_runtime dir")
	}
	if err := os.Unsetenv("SSH_AUTH_SOCK"); err != nil {
		Fail("unable to unset SSH_AUTH_SOCK")
	}
	if err := os.Setenv("PODMAN_CONNECTIONS_CONF", filepath.Join(homeDir, "connections.json")); err != nil {
		Fail("failed to set PODMAN_CONNECTIONS_CONF")
	}
	mb, err := newMB()
	if err != nil {
		Fail(fmt.Sprintf("failed to create machine test: %q", err))
	}
	return homeDir, mb
}
func teardown(origHomeDir string, testDir string) {
	if err := guardedRemoveAll(testDir); err != nil {
		Fail(fmt.Sprintf("failed to remove test dir: %q", err))
	}
	// this needs to be last in teardown
	if err := os.Setenv("HOME", origHomeDir); err != nil {
		Fail("failed to set home dir")
	}
	if runtime.GOOS == "windows" {
		if err := os.Setenv("USERPROFILE", origHomeDir); err != nil {
			Fail("failed to set windows home dir back to original")
		}
	}
}

// guardedRemoveAll functions much like os.RemoveAll but
// will not delete certain catastrophic paths.
func guardedRemoveAll(path string) error {
	if path == "" || path == "/" {
		return fmt.Errorf("refusing to recursively delete `%s`", path)
	}
	return os.RemoveAll(path)
}
