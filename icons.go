package main

import (
	"context"
	"fmt"
	"io"
	"log"
	"net/http"

	"suah.dev/gostart/data"
)

func updateIcons() {
	ctx := context.Background()
	links, err := app.queries.GetAllLinks(ctx)
	if err != nil {
		log.Println("can't get links: ", err)
	}

	for _, link := range links {
		fmt.Println(link.LogoUrl)
		if link.LogoUrl == "" {
			continue
		}
		resp, err := http.Get(link.LogoUrl)
		if err != nil {
			log.Println(err)
			continue
		}

		body, err := io.ReadAll(resp.Body)
		if err != nil {
			log.Println(err)
			continue
		}
		err = resp.Body.Close()
		if err != nil {
			log.Println(err)
			continue
		}
		contentType := resp.Header.Get("Content-Type")

		err = app.queries.AddIcon(ctx, data.AddIconParams{
			OwnerID:     link.OwnerID,
			LinkID:      link.ID,
			ContentType: contentType,
			Data:        body,
		})
		if err != nil {
			log.Println("can't add icon: ", err)

		}
	}
}
