package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"html/template"
	"image"
	"image/color"
	"image/png"
	"net/http"
	"strconv"
	"time"
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
	ownerID, ok := ctx.Value(ownerKey).(int64)
	if !ok {
		http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
		return
	}
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

	icon, err := app.queries.GetIconByLinkID(ctx, data.GetIconByLinkIDParams{
		LinkID:  int64(linkID),
		OwnerID: ownerID,
	})

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
	watches, err := app.queries.GetAllWatchItemsByOwner(app.ctx, ownerID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
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
	err = app.queries.DeleteWatchItem(app.ctx, data.DeleteWatchItemParams{ID: int64(watchID), OwnerID: ownerID})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
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

	_, err := app.queries.AddWatchItem(app.ctx, *d)
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

	_, err := app.queries.AddPullRequest(app.ctx, *d)
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
	err = app.queries.DeletePullRequest(app.ctx, data.DeletePullRequestParams{ID: int64(prID), OwnerID: ownerID})
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
	prs, err := app.queries.GetAllPullRequests(app.ctx, ownerID)
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
	links, err := app.queries.GetAllLinksForOwner(app.ctx, ownerID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	linksJson, err := json.Marshal(links)
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

	_, err := app.queries.AddLink(app.ctx, *d)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
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

	_, err := app.queries.AddPullRequestIgnore(app.ctx, *d)
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
	err = app.queries.DeleteLink(app.ctx, data.DeleteLinkParams{ID: int64(linkID), OwnerID: ownerID})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

var templateFuncs = template.FuncMap{
	"includeWatch": func(repo string, number int, ignoreList []data.PullRequestIgnore) bool {
		for _, pri := range ignoreList {
			if pri.Repo == repo && pri.Number == int64(number) {
				return false
			}
		}
		return true
	},
	"remaining": func(d time.Time) string {
		ct := time.Now()
		left := d.Sub(ct)
		return fmt.Sprintf("%3.f", left.Minutes())
	},
}

func index(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	systemOwner, err := app.getOwner(r)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	ownerID, ok := ctx.Value(ownerKey).(int64)
	if !ok {
		http.Error(w, http.StatusText(http.StatusUnprocessableEntity), http.StatusUnprocessableEntity)
		return
	}
	dbCtx := context.Background()
	links, err := app.queries.GetAllLinksForOwner(dbCtx, ownerID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	owner, err := app.queries.GetOwner(ctx, ownerID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// TODO: maybe I can do this with an sql join...
	filteredLinks := []data.Link{}
	for _, l := range links {
		if !owner.ShowShared && l.OwnerID != ownerID {
			continue
		}
		filteredLinks = append(filteredLinks, l)
	}

	prs, err := app.queries.GetAllPullRequests(dbCtx, ownerID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	ignores, err := app.queries.GetAllPullRequestIgnores(ctx, ownerID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	stuff := &Page{
		Node:          *systemOwner,
		System:        owner,
		Title:         "StartPage",
		Links:         filteredLinks,
		PullRequests:  prs,
		Watches:       app.watches.forID(ownerID),
		CurrentLimits: app.watches.GetLimits(),
		Ignores:       ignores,
	}

	stuff.Sort()

	tmpl := template.Must(
		template.New("").Funcs(templateFuncs).ParseFS(templates, "templates/main.html"),
	)

	err = tmpl.ExecuteTemplate(w, "main.html", stuff)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
}
