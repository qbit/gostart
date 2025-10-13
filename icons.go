package main

import (
	"context"
	"io"
	"log"
	"net/http"
	"net/url"

	"suah.dev/gostart/data"
)

func makeFavicon(u string) (string, error) {
	furl, err := url.Parse(u)
	if err != nil {
		return "", err
	}
	furl.Path = ""
	furl.RawQuery = ""
	furl.Fragment = ""
	iconUrl, err := url.JoinPath(furl.String(), "/favicon.ico")
	if err != nil {
		return "", err
	}
	return iconUrl, nil
}

func updateIcons() {
	ctx := context.Background()
	links, err := app.queries.GetAllLinks(ctx)
	if err != nil {
		log.Println("can't get links: ", err)
	}

	for _, link := range links {
		iconUrl := link.LogoUrl
		if link.LogoUrl == "" {
			furl, err := makeFavicon(link.Url)
			if err != nil {
				log.Println(err)
				continue
			}
			iconUrl = furl
		}
		resp, err := http.Get(iconUrl)
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
