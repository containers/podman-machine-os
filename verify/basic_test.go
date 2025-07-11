package verify

import (
	"runtime"

	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("run basic podman commands", func() {
	var (
		mb      *imageTestBuilder
		testDir string
	)
	BeforeEach(func() {
		testDir, mb = setup()
		DeferCleanup(func() {
			// stop and remove all machines first before deleting the processes
			clean := []string{"machine", "reset", "-f"}
			session, err := mb.setCmd(clean).run()

			teardown(originalHomeDir, testDir)

			// check errors only after we called teardown() otherwise it is not called on failures
			Expect(err).ToNot(HaveOccurred(), "cleaning up after test")
			Expect(session).To(Exit(0))
		})
	})

	It("Basic ops", func() {
		imgName := "quay.io/libpod/testimage:20241011"
		machineName, session, err := mb.initNowWithName()
		Expect(err).ToNot(HaveOccurred())
		Expect(session).To(Exit(0))

		// Pull an image
		pull := []string{"pull", imgName}
		pullSession, err := mb.setCmd(pull).run()
		Expect(err).ToNot(HaveOccurred())
		Expect(pullSession).To(Exit(0))

		// Check Images
		checkCmd := []string{"images", "--format", "{{.Repository}}:{{.Tag}}"}
		checkImages, err := mb.setCmd(checkCmd).run()
		Expect(err).ToNot(HaveOccurred())
		Expect(checkImages).To(Exit(0))
		Expect(len(checkImages.outputToStringSlice())).To(Equal(1))
		Expect(checkImages.outputToStringSlice()).To(ContainElement(imgName))

		// Run simple container and check that host-gateway works
		// https://github.com/containers/podman/issues/21681
		runCmdDate := []string{"run", "-it", "--add-host=foobar123:host-gateway", imgName, "cat", "/etc/hosts"}
		runCmdDateSession, err := mb.setCmd(runCmdDate).run()
		Expect(err).ToNot(HaveOccurred())
		Expect(runCmdDateSession).To(Exit(0))
		Expect(runCmdDateSession.outputToString()).To(ContainSubstring("foobar123"))

		// Run container in background
		runCmdTop := []string{"run", "-dt", imgName, "top"}
		runTopSession, err := mb.setCmd(runCmdTop).run()
		Expect(err).ToNot(HaveOccurred())
		Expect(runTopSession).To(Exit(0))

		// Check containers
		psCmd := []string{"ps", "-q"}
		psCmdSession, err := mb.setCmd(psCmd).run()
		Expect(err).ToNot(HaveOccurred())
		Expect(psCmdSession).To(Exit(0))
		Expect(len(psCmdSession.outputToStringSlice())).To(Equal(1))

		// Check all containers
		psCmdAll := []string{"ps", "-aq"}
		psCmdSessionAll, err := mb.setCmd(psCmdAll).run()
		Expect(err).ToNot(HaveOccurred())
		Expect(psCmdSessionAll).To(Exit(0))
		Expect(len(psCmdSessionAll.outputToStringSlice())).To(Equal(2))

		// Stop all containers
		stopCmd := []string{"stop", "-a"}
		stopSession, err := mb.setCmd(stopCmd).run()
		Expect(err).ToNot(HaveOccurred())
		Expect(stopSession).To(Exit(0))

		// Check container stopped
		doubleCheckCmd := []string{"ps", "-q"}
		doubleCheckCmdSession, err := mb.setCmd(doubleCheckCmd).run()
		Expect(err).ToNot(HaveOccurred())
		Expect(doubleCheckCmdSession).To(Exit(0))
		Expect(len(doubleCheckCmdSession.outputToStringSlice())).To(Equal(0))

		// systemd-binfmt.service is failing to configure emulation, so we cannot test that there yet
		// https://github.com/containers/podman/issues/19961
		if vmTestProvider != WSLVirt {
			// Test emulation so we know it always works, we had a kernel update
			// broke rosetta on applehv so we like to catch that the next time.
			var expectedArch string
			var goArch string
			switch runtime.GOARCH {
			case "amd64":
				goArch = "arm64"
				expectedArch = "aarch64"
			case "arm64":
				goArch = "amd64"
				expectedArch = "x86_64"
			}
			// quiet to not get the pull output
			archCommand := []string{"run", "--quiet", "--platform", "linux/" + goArch, imgName, "arch"}
			archSession, err := mb.setCmd(archCommand).run()
			Expect(err).ToNot(HaveOccurred())
			Expect(archSession).To(Exit(0))
			Expect(archSession.outputToString()).To(Equal(expectedArch))
		}

		// Stop machine
		stopMachineCmd := []string{"machine", "stop", machineName}
		StopMachineSession, err := mb.setCmd(stopMachineCmd).run()
		Expect(err).ToNot(HaveOccurred())
		Expect(StopMachineSession).To(Exit(0))

		// Remove machine
		removeMachineCmd := []string{"machine", "rm", "-f", machineName}
		removeMachineSession, err := mb.setCmd(removeMachineCmd).run()
		Expect(err).ToNot(HaveOccurred())
		Expect(removeMachineSession).To(Exit(0))
	})

	It("machine stop/start cycle", func() {
		// We have seen an issue while stopping and starting machines again
		// and then causing ssh failures on the second start. So test it.
		machineName, session, err := mb.initNowWithName()
		Expect(err).ToNot(HaveOccurred())
		Expect(session).To(Exit(0))

		stopMachineCmd := []string{"machine", "stop", machineName}
		stopMachineSession, err := mb.setCmd(stopMachineCmd).run()
		Expect(err).ToNot(HaveOccurred())
		Expect(stopMachineSession).To(Exit(0))

		startMachineCmd := []string{"machine", "start", machineName}
		startMachineSession, err := mb.setCmd(startMachineCmd).run()
		Expect(err).ToNot(HaveOccurred())
		Expect(startMachineSession).To(Exit(0))
	})
})
