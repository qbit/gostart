package main

import (
	"bytes"
	"cmp"
	"context"
	"encoding/json"
	"image"
	"image/color"
	"image/png"
	"log"
	"net/http"
	"slices"
	"strconv"
	"unicode"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/render"
	"golang.org/x/image/font"
	"golang.org/x/image/font/basicfont"
	"golang.org/x/image/math/fixed"
	"suah.dev/gostart/data"
)

// TODO: make this more generic.

type ctxKey string

func (c ctxKey) String() string {
	return string(c)
}

const ownerKey = ctxKey("ownerid")

func OwnerCtx(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		owner, err := app.getOwner(r)
		if err != nil {
			http.Error(w, err.Error(), http.StatusUnauthorized)
			return
		}
		ownerID := int64(owner.ID)
		ctx := context.WithValue(r.Context(), ownerKey, ownerID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func IconCacher(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "max-age=604800")
		next.ServeHTTP(w, r)
	})
}

func iconGET(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	/*
		ownerID, ok := ctx.Value(ownerKey).(int64)
		if !ok {
			http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
			return
		}
	*/
	linkID, err := strconv.Atoi(chi.URLParam(r, "linkID"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	link, err := app.queries.GetLinkByID(ctx, int64(linkID))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	icon, err := app.queries.GetIconByLinkID(ctx, int64(linkID))
	if err != nil {
		size := 24
		img := image.NewRGBA(image.Rect(0, 0, size, size))
		co := color.RGBA{A: 255}
		point := fixed.Point26_6{
			X: fixed.I(size/2 - basicfont.Face7x13.Width),
			Y: fixed.I(size / 2),
		}
		d := &font.Drawer{
			Dst:  img,
			Src:  image.NewUniform(co),
			Face: basicfont.Face7x13,
			Dot:  point,
		}

		r := []rune(link.Name)
		l := string(unicode.ToUpper(r[0]))

		d.DrawString(l)

		buf := new(bytes.Buffer)

		if err := png.Encode(buf, img); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		} else {
			icon.Data = buf.Bytes()
			icon.ContentType = "image/png"
		}
	}

	w.Header().Add("Content-type", icon.ContentType)
	w.WriteHeader(200)
	_, _ = w.Write(icon.Data)
}

func watchitemGET(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	ownerID, ok := ctx.Value(ownerKey).(int64)
	if !ok {
		http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
		return
	}

	watches := app.watches.forID(ownerID)

	wJson, err := json.Marshal(watches)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Add("Content-type", "application/json")
	w.WriteHeader(200)
	_, err = w.Write(wJson)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func watchitemDELETE(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	ownerID, ok := ctx.Value(ownerKey).(int64)
	if !ok {
		http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
		return
	}
	watchID, err := strconv.Atoi(chi.URLParam(r, "watchID"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
	err = app.queries.DeleteWatchItem(ctx, data.DeleteWatchItemParams{ID: int64(watchID), OwnerID: ownerID})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
	app.removeWatch(watchID)
}

func watchitemPOST(w http.ResponseWriter, r *http.Request) {
	d := &data.AddWatchItemParams{}
	if err := render.Decode(r, d); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	ctx := r.Context()
	ownerID, ok := ctx.Value(ownerKey).(int64)
	if !ok {
		http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
		return
	}

	d.OwnerID = ownerID

	_, err := app.queries.AddWatchItem(ctx, *d)
	if err != nil {
		http.Error(w, err.Error(), http.StatusUnprocessableEntity)
		return
	}
}

func pullrequestsPOST(w http.ResponseWriter, r *http.Request) {
	d := &data.AddPullRequestParams{}
	if err := render.Decode(r, d); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	ctx := r.Context()
	ownerID, ok := ctx.Value(ownerKey).(int64)
	if !ok {
		http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
		return
	}

	d.OwnerID = ownerID

	_, err := app.queries.AddPullRequest(ctx, *d)
	if err != nil {
		http.Error(w, err.Error(), http.StatusUnprocessableEntity)
		return
	}
}

func pullrequestsDELETE(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	ownerID, ok := ctx.Value(ownerKey).(int64)
	if !ok {
		http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
		return
	}
	prID, err := strconv.Atoi(chi.URLParam(r, "prID"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
	err = app.queries.DeletePullRequest(ctx, data.DeletePullRequestParams{ID: int64(prID), OwnerID: ownerID})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func pullrequestsGET(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	ownerID, ok := ctx.Value(ownerKey).(int64)
	if !ok {
		http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
		return
	}
	prs, err := app.queries.GetAllPullRequests(ctx, ownerID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	prJson, err := json.Marshal(prs)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Add("Content-type", "application/json")
	w.WriteHeader(200)
	_, err = w.Write(prJson)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func linksGET(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	ownerID, ok := ctx.Value(ownerKey).(int64)
	if !ok {
		http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
		return
	}
	owner, err := app.queries.GetOwner(ctx, ownerID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	links, err := app.queries.GetAllLinksForOwner(ctx, ownerID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	filteredLinks := []data.Link{}
	for _, l := range links {
		if !owner.ShowShared && l.OwnerID != ownerID {
			continue
		}
		filteredLinks = append(filteredLinks, l)
	}

	slices.SortFunc(filteredLinks, func(a, b data.Link) int {
		return cmp.Compare(b.Clicked, a.Clicked)
	})

	linksJson, err := json.Marshal(filteredLinks)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Add("Content-type", "application/json")
	w.WriteHeader(200)
	_, err = w.Write(linksJson)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func linksPOST(w http.ResponseWriter, r *http.Request) {
	d := &data.AddLinkParams{}
	if err := render.Decode(r, d); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	ctx := r.Context()
	ownerID, ok := ctx.Value(ownerKey).(int64)
	if !ok {
		http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
		return
	}

	d.OwnerID = ownerID

	_, err := app.queries.AddLink(ctx, *d)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func prignoreGET(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	ownerID, ok := ctx.Value(ownerKey).(int64)
	if !ok {
		http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
		return
	}
	prIgnores, err := app.queries.GetAllPullRequestIgnores(ctx, ownerID)
	if err != nil {
		log.Println(err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	prJson, err := json.Marshal(prIgnores)
	if err != nil {
		log.Println(err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Add("Content-type", "application/json")
	w.WriteHeader(200)
	_, err = w.Write(prJson)
	if err != nil {
		log.Println(err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func prignoreDELETE(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	ownerID, ok := ctx.Value(ownerKey).(int64)
	if !ok {
		http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
		return
	}
	ignoreID, err := strconv.Atoi(chi.URLParam(r, "ignoreID"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
	err = app.queries.DeleteIgnore(ctx, data.DeleteIgnoreParams{ID: int64(ignoreID), OwnerID: ownerID})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func prignorePOST(w http.ResponseWriter, r *http.Request) {
	d := &data.AddPullRequestIgnoreParams{}
	if err := render.Decode(r, d); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	ctx := r.Context()
	ownerID, ok := ctx.Value(ownerKey).(int64)
	if !ok {
		http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
		return
	}

	d.OwnerID = ownerID

	_, err := app.queries.AddPullRequestIgnore(ctx, *d)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}

func linkDELETE(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	ownerID, ok := ctx.Value(ownerKey).(int64)
	if !ok {
		http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
		return
	}
	linkID, err := strconv.Atoi(chi.URLParam(r, "linkID"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
	err = app.queries.DeleteLink(ctx, data.DeleteLinkParams{ID: int64(linkID), OwnerID: ownerID})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func linkGET(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	ownerID, ok := ctx.Value(ownerKey).(int64)
	if !ok {
		http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
		return
	}
	linkID, err := strconv.Atoi(chi.URLParam(r, "linkID"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
	link, err := app.queries.IncrementLink(ctx, data.IncrementLinkParams{ID: int64(linkID), OwnerID: ownerID})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
	http.Redirect(w, r, link.Url, http.StatusSeeOther)
}
