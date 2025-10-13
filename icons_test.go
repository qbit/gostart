package main

import "testing"

func TestMakeFavicon(t *testing.T) {
	testUrls := map[string]string{
		"https://google.com/thing/stuff/wat": "https://google.com/favicon.ico",
		"https://lobste.rs/search?q=potato":  "https://lobste.rs/favicon.ico",
	}

	for u, expected := range testUrls {
		furl, err := makeFavicon(u)
		if err != nil {
			t.Fatal(err)
		}
		if furl != expected {
			t.Fatalf("expected %q but got %q", expected, furl)
		}
	}
}
