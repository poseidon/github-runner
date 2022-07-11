package cmd

import (
	"context"
	"fmt"
	"log"
	"net/http"

	"github.com/bradleyfalzon/ghinstallation/v2"
	"github.com/google/go-github/v45/github"
	"github.com/spf13/cobra"
)

var registrationTokenCmd = &cobra.Command{
	Use:   "registration-token",
	Short: "Fetches a Github token (TTL 1 hour) that can register a Github self-hosted runner",
	Run: func(cmd *cobra.Command, args []string) {
		fetchRegistrationToken()
	},
}

func fetchRegistrationToken() {
	transport, err := ghinstallation.NewKeyFromFile(http.DefaultTransport, appFlags.AppID, appFlags.InstallID, appFlags.AppKeyPath)
	if err != nil {
		log.Printf("Authenticate as Github App %d Installation %d using %s", appFlags.AppID, appFlags.InstallID, appFlags.AppKeyPath)
		log.Fatalf("gha: error authenticating as Github App: %v", err)
	}

	// Github Client authenticated as Github App
	client := github.NewClient(&http.Client{Transport: transport})

	// create a token for registering an organization self-hosted runner
	regToken, _, err := client.Actions.CreateOrganizationRegistrationToken(context.Background(), appFlags.Organization)
	if err != nil {
		log.Fatalf("gha: error fetching registration token for org %s: %v", appFlags.Organization, err)
	}

	fmt.Println(regToken.GetToken())
}
