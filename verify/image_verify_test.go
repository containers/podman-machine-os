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
	tmpDir       = os.TempDir()
	podmanBinary string
	err          error
	imagePath    string
)

func init() {
	podmanBinary, err = getPodmanBinary()
	if err != nil {
		Fail(fmt.Sprintf("Failed to find podman binary: %v", err))
	}
	fmt.Printf("Using podman binary: %s\n", podmanBinary)
	if value, ok := os.LookupEnv("TMPDIR"); !ok {
		tmpDir = value
	}

	value, ok := os.LookupEnv("MACHINE_IMAGE_PATH")
	if !ok {
		Fail("unable to find image path")
	}
	imagePath = value
}

// TestLibpod ginkgo master function
func TestMachine(t *testing.T) {
	RegisterFailHandler(Fail)
	RunSpecs(t, "Podman Machine tests")
}

var _ = BeforeSuite(func() {
	fmt.Println("Hello world")
})

var _ = AfterEach(func() {
	clean := []string{"machine", "reset", "-f"}
	_, err := mb.setCmd(clean).run()
	if err != nil {
		fmt.Println("Error cleaning up after test: ", err)
	}
})

var _ = SynchronizedAfterSuite(func() {}, func() {
	//slices.SortFunc(timings, func(a, b timing) int {
	//	return cmp.Compare(a.length, b.length)
	//})
	//for _, t := range timings {
	//	GinkgoWriter.Printf("%s\t\t%f seconds\n", t.name, t.length.Seconds())
	//}
})

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

var (
	mb      *imageTestBuilder
	testDir string
)

var _ = BeforeEach(func() {
	testDir, mb = setup()
	DeferCleanup(func() {
		teardown(originalHomeDir, testDir)
	})
})

// guardedRemoveAll functions much like os.RemoveAll but
// will not delete certain catastrophic paths.
func guardedRemoveAll(path string) error {
	if path == "" || path == "/" {
		return fmt.Errorf("refusing to recursively delete `%s`", path)
	}
	return os.RemoveAll(path)
}
