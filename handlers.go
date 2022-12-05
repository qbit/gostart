package main

import (
	"context"
	"encoding/json"
	"html/template"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/render"
	"suah.dev/gostart/data"
)

// TODO: make this more generic.

func OwnerCtx(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		owner, err := app.getOwner(r)
		if err != nil {
			http.Error(w, err.Error(), http.StatusUnauthorized)
			return
		}
		ownerID := int64(owner.ID)
		ctx := context.WithValue(r.Context(), "ownerid", ownerID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func iconGET(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	ownerID, ok := ctx.Value("ownerid").(int64)
	if !ok {
		http.Error(w, http.StatusText(422), 422)
		return
	}
	linkID, err := strconv.Atoi(chi.URLParam(r, "linkID"))
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}

	icon, err := app.queries.GetIconByLinkID(ctx, data.GetIconByLinkIDParams{
		LinkID:  int64(linkID),
		OwnerID: ownerID,
	})
	w.Header().Add("Content-type", icon.ContentType)
	w.WriteHeader(200)
	_, err = w.Write(icon.Data)
}

func watchitemGET(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	ownerID, ok := ctx.Value("ownerid").(int64)
	if !ok {
		http.Error(w, http.StatusText(422), 422)
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
	ownerID, ok := ctx.Value("ownerid").(int64)
	if !ok {
		http.Error(w, http.StatusText(422), 422)
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
	ownerID, ok := ctx.Value("ownerid").(int64)
	if !ok {
		http.Error(w, http.StatusText(422), 422)
		return
	}

	d.OwnerID = ownerID

	_, err := app.queries.AddWatchItem(app.ctx, *d)
	if err != nil {
		http.Error(w, http.StatusText(422), 422)
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
	ownerID, ok := ctx.Value("ownerid").(int64)
	if !ok {
		http.Error(w, http.StatusText(422), 422)
		return
	}

	d.OwnerID = ownerID

	_, err := app.queries.AddPullRequest(app.ctx, *d)
	if err != nil {
		http.Error(w, http.StatusText(422), 422)
		return
	}
}

func pullrequestsDELETE(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	ownerID, ok := ctx.Value("ownerid").(int64)
	if !ok {
		http.Error(w, http.StatusText(422), 422)
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
	ownerID, ok := ctx.Value("ownerid").(int64)
	if !ok {
		http.Error(w, http.StatusText(422), 422)
		return
	}
	prs, err := app.queries.GetAllPullRequests(app.ctx, data.GetAllPullRequestsParams{
		OwnerID:   ownerID,
		OwnerID_2: ownerID,
	})
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
	ownerID, ok := ctx.Value("ownerid").(int64)
	if !ok {
		http.Error(w, http.StatusText(422), 422)
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
	ownerID, ok := ctx.Value("ownerid").(int64)
	if !ok {
		http.Error(w, http.StatusText(422), 422)
		return
	}

	d.OwnerID = ownerID

	_, err := app.queries.AddLink(app.ctx, *d)
	if err != nil {
		http.Error(w, http.StatusText(422), 422)
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
	ownerID, ok := ctx.Value("ownerid").(int64)
	if !ok {
		http.Error(w, http.StatusText(422), 422)
		return
	}

	d.OwnerID = ownerID

	_, err := app.queries.AddPullRequestIgnore(app.ctx, *d)
	if err != nil {
		http.Error(w, http.StatusText(422), 422)
		return
	}
}

func linkDELETE(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	ownerID, ok := ctx.Value("ownerid").(int64)
	if !ok {
		http.Error(w, http.StatusText(422), 422)
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
}

func index(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	owner, err := app.getOwner(r)
	if err != nil {
		http.Error(w, http.StatusText(422), 422)
		return
	}
	ownerID, ok := ctx.Value("ownerid").(int64)
	if !ok {
		http.Error(w, http.StatusText(422), 422)
		return
	}
	dbCtx := context.Background()
	links, err := app.queries.GetAllLinksForOwner(dbCtx, ownerID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	prs, err := app.queries.GetAllPullRequests(dbCtx, data.GetAllPullRequestsParams{
		OwnerID:   ownerID,
		OwnerID_2: ownerID,
	})
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
		Node:          *owner,
		Title:         "StartPage",
		Links:         links,
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
