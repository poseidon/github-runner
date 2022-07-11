package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

// rootCmd represents the root command in the tree of subcommands
var rootCmd = &cobra.Command{
	Use:   "gha",
	Short: "gha (GitHub App) fetches self-hosted runner registration tokens",
	Long:  "gha (GitHub App) uses long-lived Github App Installation credentials to fetch Github self-hosted runner registration tokens",
}

// Execute adds subcommands to the root and defines flags.
func Execute() {
	// subcommands
	rootCmd.AddCommand(registrationTokenCmd)
	rootCmd.AddCommand(versionCmd)

	// local flags
	addAppFlags()

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

var appFlags struct {
	AppID        int64
	AppKeyPath   string
	InstallID    int64
	Organization string
}

// addAppFlags registers appFlags.
func addAppFlags() {
	registrationTokenCmd.Flags().Int64Var(&appFlags.AppID, "app-id", 0, "Github App ID")
	registrationTokenCmd.Flags().StringVar(&appFlags.AppKeyPath, "app-key-path", "", "Github App PEM private key path")
	registrationTokenCmd.Flags().Int64Var(&appFlags.InstallID, "install-id", 0, "Github App Installation ID")
	registrationTokenCmd.Flags().StringVar(&appFlags.Organization, "organization", "", "Github Organization of installation")
	_ = registrationTokenCmd.MarkFlagRequired("app-id")
	_ = registrationTokenCmd.MarkFlagRequired("app-key-path")
	_ = registrationTokenCmd.MarkFlagRequired("install-id")
	_ = registrationTokenCmd.MarkFlagRequired("organization")
}
