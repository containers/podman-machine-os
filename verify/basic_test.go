package verify_test

import (
	. "github.com/onsi/ginkgo/v2"
	. "github.com/onsi/gomega"
	. "github.com/onsi/gomega/gexec"
)

var _ = Describe("run basic podman commands", func() {
	It("Basic ops", func() {
		imgName := "docker.io/library/alpine"
		machineName, session, err := mb.initNowWithName()
		Expect(err).ToNot(HaveOccurred())
		Expect(session).To(Exit(0))

		// Pull an image
		pull := []string{"pull", imgName}
		pullSession, err := mb.setCmd(pull).run()
		Expect(err).ToNot(HaveOccurred())
		Expect(pullSession).To(Exit(0))

		// Check Images
		checkCmd := []string{"images", "--format", "{{.Repository}}"}
		checkImages, err := mb.setCmd(checkCmd).run()
		Expect(err).ToNot(HaveOccurred())
		Expect(checkImages).To(Exit(0))
		Expect(len(checkImages.outputToStringSlice())).To(Equal(1))
		Expect(checkImages.outputToStringSlice()).To(ContainElement(imgName))

		// Run simple container
		runCmdDate := []string{"run", "-it", imgName, "ls"}
		runCmdDateSession, err := mb.setCmd(runCmdDate).run()
		Expect(err).ToNot(HaveOccurred())
		Expect(runCmdDateSession).To(Exit(0))

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
})
