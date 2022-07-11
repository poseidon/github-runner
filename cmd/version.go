package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

// version provided by compile time -ldflags
var version = "was not built properly"

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print version and exit",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("gha %s\n", version)
	},
}
