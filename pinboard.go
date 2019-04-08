//
// Copyright (C) 2019-2019 Marcus Rohrmoser, https://code.mro.name/mro/pinboard4shaarli
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

package main

import (
	"bytes"
	"encoding/xml"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/http/cgi"
	"net/http/cookiejar"
	"net/url"
	"os"
	"path"
	"path/filepath"
	"strings"
	"time"

	"github.com/yhat/scrape"
	"golang.org/x/net/html"
	"golang.org/x/net/html/atom"
	// "golang.org/x/net/html/charset"
	"golang.org/x/net/publicsuffix"
)

const (
	ShaarliDate = "20060102_150405"
	IsoDate     = "2006-01-02"
)

var GitSHA1 = "Please set -ldflags \"-X main.GitSHA1=$(git rev-parse --short HEAD)\"" // https://medium.com/@joshroppo/setting-go-1-5-variables-at-compile-time-for-versioning-5b30a965d33e

// even cooler: https://stackoverflow.com/a/8363629
//
// inspired by // https://coderwall.com/p/cp5fya/measuring-execution-time-in-go
func trace(name string) (string, time.Time) { return name, time.Now() }
func un(name string, start time.Time)       { log.Printf("%s took %s", name, time.Since(start)) }

func main() {
	if cli() {
		return
	}

	if true {
		// lighttpd doesn't seem to like more than one (per-vhost) server.breakagelog
		log.SetOutput(os.Stderr)
	} else { // log to custom logfile rather than stderr (may not be reachable on shared hosting)
	}

	// - http.StripPrefix (and just keep PATH_INFO as Request.URL.path)
	// - route
	// - authenticate
	// - extract parameters
	// - call api backend method
	// - build response

	h := handleMux(os.Getenv("PATH_INFO"))
	if err := cgi.Serve(http.TimeoutHandler(h, 5*time.Second, "🐌")); err != nil {
		log.Fatal(err)
	}
}

/// $ ./pinboard4shaarli.cgi --help | -h | -?
/// $ ./pinboard4shaarli.cgi https://demo.shaarli.org/pinboard4shaarli.cgi/v1/about
/// $ ./pinboard4shaarli.cgi 'https://uid:pwd@demo.shaarli.org/pinboard4shaarli.cgi/v1/posts/get?url=http://m.heise.de/12'
/// $ ./pinboard4shaarli.cgi 'https://uid:pwd@demo.shaarli.org/pinboard4shaarli.cgi/v1/posts/add?url=http://m.heise.de/12&description=foo'
/// todo
/// $ ./pinboard4shaarli.cgi https://uid:pwd@demo.shaarli.org/pinboard4shaarli.cgi/v1/user/api_token
/// $ ./pinboard4shaarli.cgi --data-urlencode auth_token=uid:XYZUUU --data-urlencode url=https://m.heise.de/foo https://demo.shaarli.org/pinboard4shaarli.cgi/v1/posts/get
///
func cli() bool {
	// test if we're running cli
	if len(os.Args) == 1 {
		return false
	}

	for i, a := range os.Args[2:] {
		fmt.Fprintf(os.Stderr, "  %d: %s\n", i, a)
	}

	// todo?: add parameters

	if req, err := http.NewRequest(http.MethodGet, os.Args[1], nil); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err.Error())
	} else {
		usr := req.URL.User
		if pwd, isset := usr.Password(); isset {
			req.SetBasicAuth(usr.Username(), pwd)
		}
		bin := filepath.Base(os.Args[0])
		str := req.URL.Path
		idx := strings.LastIndex(str, bin)
		pi := str[idx+len(bin):]
		handleMux(pi)(reqWri{r: req, f: os.Stderr, h: http.Header{}}, req)
	}

	return true
}

type reqWri struct {
	r *http.Request
	f io.Writer
	h http.Header
}

func (w reqWri) Header() http.Header {
	return w.h
}
func (w reqWri) Write(b []byte) (int, error) {
	return w.f.Write(b)
}
func (w reqWri) WriteHeader(statusCode int) {
	const LF = "\r\n"
	fmt.Fprintf(w.f, "%s %d %s"+LF, w.r.Proto, statusCode, http.StatusText(statusCode))
	for k, v := range w.Header() {
		fmt.Fprintf(w.f, "%s: %s"+LF, k, strings.Join(v, " "))
	}
	fmt.Fprintf(w.f, LF)
}

// https://pinboard.in/api
func handleMux(path_info string) http.HandlerFunc {
	agent := strings.Join([]string{"https://code.mro.name/mro/pinboard4shaarli", "#", version, "+", GitSHA1}, "")
	// https://stackoverflow.com/a/18414432
	options := cookiejar.Options{PublicSuffixList: publicsuffix.List}
	
	return func(w http.ResponseWriter, r *http.Request) {
		defer un(trace(strings.Join([]string{"v", version, "+", GitSHA1, " ", r.RemoteAddr, " ", r.Method, " ", r.URL.String()}, "")))

		w.Header().Set(http.CanonicalHeaderKey("X-Powered-By"), agent)
		w.Header().Set(http.CanonicalHeaderKey("Content-Type"), "text/xml; charset=utf-8")

		if http.MethodGet != r.Method {
			w.Header().Set(http.CanonicalHeaderKey("Allow"), http.MethodGet)
			http.Error(w, "All API methods are GET requests, even when good REST habits suggest they should use a different verb.", http.StatusMethodNotAllowed)
			return
		}

		jar, err := cookiejar.New(&options)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		client := http.Client{Jar: jar, Timeout: 2 * time.Second}

		asset := func(name, mime string) {
			w.Header().Set(http.CanonicalHeaderKey("Content-Type"), mime)
			if b, err := Asset(name); err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
			} else {
				w.Write(b)
			}
		}

		base := *r.URL
		base.Path = path.Join(base.Path[0:len(base.Path)-len(path_info)], "..", "index.php")

		switch path_info {
		case "":
			http.Redirect(w, r, "about", http.StatusFound)
			return
		case "/about":
			asset("doap.rdf", "application/rdf+xml")
			return
		case "/v1":
			http.Redirect(w, r, "v1/openapi.yaml", http.StatusFound)
			return
		case "/v1/openapi.yaml":
			asset("openapi.yaml", "text/x-yaml; charset=utf-8")
			return

			// now comes the /real/ API
		case
			"/v1/posts/get":
			// pretend to add, but don't actually do it, but return the form preset values.
			uid, pwd, ok := r.BasicAuth()
			if !ok {
				http.Error(w, "Basic Pre-Authentication required.", http.StatusForbidden)
				return
			}

			params := r.URL.Query()
			if 1 != len(params["url"]) {
				http.Error(w, "Required parameter missing: url", http.StatusBadRequest)
				return
			}
			p_url := params["url"][0]

			/*
				if 1 != len(params["description"]) {
					http.Error(w, "Required parameter missing: description", http.StatusBadRequest)
					return
				}
				p_description := params["description"][0]

				p_extended := ""
				if 1 == len(params["extended"]) {
					p_extended = params["extended"][0]
				}

				p_tags := ""
				if 1 == len(params["tags"]) {
					p_tags = params["tags"][0]
				}
			*/

			v := url.Values{}
			v.Set("post", p_url)
			base.RawQuery = v.Encode()

			req, err := http.NewRequest(http.MethodGet, base.String(), nil)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			req.Header.Set(http.CanonicalHeaderKey("User-Agent"), agent)
			resp, err := client.Do(req)
			if err != nil {
				http.Error(w, err.Error(), http.StatusBadGateway)
				return
			}
			formLogi, err := formValuesFromReader(resp.Body, "loginform")
			resp.Body.Close()
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			formLogi.Set("login", uid)
			formLogi.Set("password", pwd)

			req, err = http.NewRequest(http.MethodPost, resp.Request.URL.String(), bytes.NewReader([]byte(formLogi.Encode())))
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			req.Header.Set(http.CanonicalHeaderKey("Content-Type"), "application/x-www-form-urlencoded")
			req.Header.Set(http.CanonicalHeaderKey("User-Agent"), agent)
			resp, err = client.Do(req)
			// resp, err = client.PostForm(resp.Request.URL.String(), formLogi)
			if err != nil {
				http.Error(w, err.Error(), http.StatusBadGateway)
				return
			}

			formLink, err := formValuesFromReader(resp.Body, "linkform")
			resp.Body.Close()
			if err != nil {
				http.Error(w, err.Error(), http.StatusBadGateway)
				return
			}
			// if we do not have a linkform, auth must have failed.
			if 0 == len(formLink) {
				http.Error(w, "Authentication failed", http.StatusForbidden)
				return
			}

			fv := func(s string) string { return formLink.Get(s) }

			tim, err := time.ParseInLocation(ShaarliDate, fv("lf_linkdate"), time.Local) // can we do any better?
			if err != nil {
				http.Error(w, err.Error(), http.StatusBadGateway)
				return
			}

			w.Write([]byte(xml.Header))
			pp := Posts{
				User: uid,
				Dt:   tim.Format(IsoDate),
				Tag:  fv("lf_tags"),
				Posts: []Post{
					Post{
						Href:        fv("lf_url"),
						Hash:        fv("lf_linkdate"),
						Description: fv("lf_title"),
						Extended:    fv("lf_description"),
						Tag:         fv("lf_tags"),
						Time:        tim.Format(time.RFC3339),
					},
				},
			}
			enc := xml.NewEncoder(w)
			enc.Encode(pp)
			enc.Flush()

			return
		case
			"/v1/posts/add":
			// extract parameters
			// agent := r.Header.Get("User-Agent")
			shared := true

			uid, pwd, ok := r.BasicAuth()
			if !ok {
				http.Error(w, "Basic Pre-Authentication required.", http.StatusForbidden)
				return
			}

			params := r.URL.Query()
			if 1 != len(params["url"]) {
				http.Error(w, "Required parameter missing: url", http.StatusBadRequest)
				return
			}
			p_url := params["url"][0]

			if 1 != len(params["description"]) {
				http.Error(w, "Required parameter missing: description", http.StatusBadRequest)
				return
			}
			p_description := params["description"][0]

			p_extended := ""
			if 1 == len(params["extended"]) {
				p_extended = params["extended"][0]
			}

			p_tags := ""
			if 1 == len(params["tags"]) {
				p_tags = params["tags"][0]
			}

			v := url.Values{}
			v.Set("post", p_url)
			v.Set("title", p_description)
			base.RawQuery = v.Encode()

			req, err := http.NewRequest(http.MethodGet, base.String(), nil)
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			req.Header.Set(http.CanonicalHeaderKey("User-Agent"), agent)
			resp, err := client.Do(req)
			if err != nil {
				http.Error(w, err.Error(), http.StatusBadGateway)
				return
			}
			formLogi, err := formValuesFromReader(resp.Body, "loginform")
			resp.Body.Close()
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}

			formLogi.Set("login", uid)
			formLogi.Set("password", pwd)

			req, err = http.NewRequest(http.MethodPost, resp.Request.URL.String(), bytes.NewReader([]byte(formLogi.Encode())))
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			req.Header.Set(http.CanonicalHeaderKey("Content-Type"), "application/x-www-form-urlencoded")
			req.Header.Set(http.CanonicalHeaderKey("User-Agent"), agent)
			resp, err = client.Do(req)
			// resp, err = client.PostForm(resp.Request.URL.String(), formLogi)
			if err != nil {
				http.Error(w, err.Error(), http.StatusBadGateway)
				return
			}

			formLink, err := formValuesFromReader(resp.Body, "linkform")
			resp.Body.Close()
			if err != nil {
				http.Error(w, err.Error(), http.StatusBadGateway)
				return
			}
			// if we do not have a linkform, auth must have failed.
			if 0 == len(formLink) {
				http.Error(w, "Authentication failed", http.StatusForbidden)
				return
			}

			// formLink.Set("lf_linkdate", ShaarliDate)
			// formLink.Set("lf_url", p_url)
			// formLink.Set("lf_title", p_description)
			formLink.Set("lf_description", p_extended)
			formLink.Set("lf_tags", p_tags)
			if shared {
				formLink.Del("lf_private")
			} else {
				formLink.Set("lf_private", "lf_private")
			}

			req, err = http.NewRequest(http.MethodPost, resp.Request.URL.String(), bytes.NewReader([]byte(formLink.Encode())))
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				return
			}
			req.Header.Set(http.CanonicalHeaderKey("Content-Type"), "application/x-www-form-urlencoded")
			req.Header.Set(http.CanonicalHeaderKey("User-Agent"), agent)
			resp, err = client.Do(req)
			// resp, err = client.PostForm(resp.Request.URL.String(), formLink)
			if err != nil {
				http.Error(w, err.Error(), http.StatusBadGateway)
				return
			}
			resp.Body.Close()

			w.Write([]byte(xml.Header))
			pp := Result{Code: "done"}
			enc := xml.NewEncoder(w)
			enc.Encode(pp)
			enc.Flush()

			return
		case
			"/v1/posts/delete":
			_, _, ok := r.BasicAuth()
			if !ok {
				http.Error(w, "Basic Pre-Authentication required.", http.StatusUnauthorized)
				return
			}

			params := r.URL.Query()
			if 1 != len(params["url"]) {
				http.Error(w, "Required parameter missing: url", http.StatusBadRequest)
				return
			}
			// p_url := params["url"][0]

			w.Write([]byte(xml.Header))
			pp := Result{Code: "not implemented yet"}
			enc := xml.NewEncoder(w)
			enc.Encode(pp)
			enc.Flush()
			return
		case
			"/v1/notes/ID",
			"/v1/notes/list",
			"/v1/posts/dates",
			"/v1/posts/suggest",
			"/v1/posts/update",
			"/v1/tags/delete",
			"/v1/tags/get",
			"/v1/tags/rename",
			"/v1/user/api_token",
			"/v1/user/secret",
			"/v1/posts/recent":
			http.Error(w, "Not Implemented", http.StatusNotImplemented)
			return
		}
		http.NotFound(w, r)
	}
}

func formValuesFromReader(r io.Reader, name string) (ret url.Values, err error) {
	root, err := html.Parse(r) // assumes r is UTF8
	if err != nil {
		return ret, err
	}

	for _, form := range scrape.FindAll(root, func(n *html.Node) bool {
		return atom.Form == n.DataAtom &&
			(name == scrape.Attr(n, "name") || name == scrape.Attr(n, "id"))
	}) {
		ret := url.Values{}
		for _, inp := range scrape.FindAll(form, func(n *html.Node) bool {
			return atom.Input == n.DataAtom || atom.Textarea == n.DataAtom
		}) {
			n := scrape.Attr(inp, "name")
			if n == "" {
				n = scrape.Attr(inp, "id")
			}

			ty := scrape.Attr(inp, "type")
			v := scrape.Attr(inp, "value")
			if atom.Textarea == inp.DataAtom {
				v = scrape.Text(inp)
			} else if v == "" && ty == "checkbox" {
				v = scrape.Attr(inp, "checked")
			}
			ret.Set(n, v)
		}
		return ret, err // return on first occurence
	}
	return ret, err
}
