//
// Copyright (C) 2019-2019 Marcus Rohrmoser, https://code.mro.name/mro/Shaarli-API-test
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
	"encoding/xml"
	"io"
	"log"
	"net/http"
	"net/http/cgi"
	"net/http/cookiejar"
	"net/url"
	"os"
	"strings"
	"time"

	"github.com/yhat/scrape"
	"golang.org/x/net/html"
	"golang.org/x/net/html/atom"
	// "golang.org/x/net/html/charset"
	"golang.org/x/net/publicsuffix"
)

var GitSHA1 = "Please set -ldflags \"-X main.GitSHA1=$(git rev-parse --short HEAD)\"" // https://medium.com/@joshroppo/setting-go-1-5-variables-at-compile-time-for-versioning-5b30a965d33e

// even cooler: https://stackoverflow.com/a/8363629
//
// inspired by // https://coderwall.com/p/cp5fya/measuring-execution-time-in-go
func trace(name string) (string, time.Time) { return name, time.Now() }
func un(name string, start time.Time)       { log.Printf("%s took %s", name, time.Since(start)) }

func main() {
	if true {
		// lighttpd doesn't seem to like more than one (per-vhost) server.breakagelog
		log.SetOutput(os.Stderr)
	} else { // log to custom logfile rather than stderr (may not be reachable on shared hosting)
	}

	if err := cgi.Serve(http.HandlerFunc(handleMux)); err != nil {
		log.Fatal(err)
	}
}

// https://pinboard.in/api
//
// All API methods are GET requests, even when good REST habits suggest they should use a different verb.
//
// v1/posts/add
// v1/posts/delete
// v1/posts/get
func handleMux(w http.ResponseWriter, r *http.Request) {
	defer un(trace(strings.Join([]string{"v", version, "+", GitSHA1, " ", r.RemoteAddr, " ", r.Method, " ", r.URL.String()}, "")))
	// w.Header().Set("Server", strings.Join([]string{myselfNamespace, CurrentShaarliGoVersion}, "#"))
	// w.Header().Set("X-Powered-By", strings.Join([]string{myselfNamespace, CurrentShaarliGoVersion}, "#"))
	//	now := time.Now()

	path_info := os.Getenv("PATH_INFO")
	base := *r.URL
	base.Path = base.Path[0:len(base.Path)-len(path_info)] + "/../index.php"
	// script_name := os.Getenv("SCRIPT_NAME")
	//	urlBase := mustParseURL(string(xmlBaseFromRequestURL(r.URL, os.Getenv("SCRIPT_NAME"))))
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")

	switch path_info {
	case "/v1/info":
		io.WriteString(w, "r.URL: "+r.URL.String()+"\n")
		io.WriteString(w, "base: "+base.String()+"\n")

		return
	case "/v1/posts/add":
		uid, pwd, ok := r.BasicAuth()
		if !ok {
			http.Error(w, "Basic Pre-Authentication required.", http.StatusUnauthorized)
			return
		}

		if "GET" != r.Method {
			http.Error(w, "All API methods are GET requests, even when good REST habits suggest they should use a different verb.", http.StatusMethodNotAllowed)
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
		base.RawQuery = v.Encode()

		// https://stackoverflow.com/a/18414432
		options := cookiejar.Options{
			PublicSuffixList: publicsuffix.List,
		}
		jar, err := cookiejar.New(&options)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		client := http.Client{Jar: jar}

		resp, err := client.Get(base.String())
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
		formLogi.Set("returnurl", r.URL.String())
		resp, err = client.PostForm(resp.Request.URL.String(), formLogi)
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

		// formLink.Set("lf_linkdate", "20190106_172531")
		// formLink.Set("lf_url", p_url)
		formLink.Set("lf_title", p_description)
		formLink.Set("lf_description", p_extended)
		formLink.Set("lf_tags", p_tags)

		resp, err = client.PostForm(resp.Request.URL.String(), formLink)
		resp.Body.Close()
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadGateway)
			return
		}

		w.Header().Set("Content-Type", "text/xml; charset=utf-8")
		io.WriteString(w, "<?xml version='1.0' encoding='UTF-8' ?><result code='done' />")
		return
	case "/v1/posts/delete":
		_, _, ok := r.BasicAuth()
		if !ok {
			http.Error(w, "Basic Pre-Authentication required.", http.StatusUnauthorized)
			return
		}

		if "GET" != r.Method {
			http.Error(w, "All API methods are GET requests, even when good REST habits suggest they should use a different verb.", http.StatusMethodNotAllowed)
			return
		}

		params := r.URL.Query()
		if 1 != len(params["url"]) {
			http.Error(w, "Required parameter missing: url", http.StatusBadRequest)
			return
		}
		// p_url := params["url"][0]

		io.WriteString(w, "bhb")
		return
	case "/v1/posts/update":
		_, _, ok := r.BasicAuth()
		if !ok {
			http.Error(w, "Basic Pre-Authentication required.", http.StatusUnauthorized)
			return
		}

		if "GET" != r.Method {
			http.Error(w, "All API methods are GET requests, even when good REST habits suggest they should use a different verb.", http.StatusMethodNotAllowed)
			return
		}

		w.Header().Set("Content-Type", "text/xml; charset=utf-8")
		io.WriteString(w, "<?xml version='1.0' encoding='UTF-8' ?><update time='2011-03-24T19:02:07Z' />")
		return
	case "/v1/posts/get":
		// pretend to add, but don't actually do it, but return the form preset values.
		uid, pwd, ok := r.BasicAuth()
		if !ok {
			http.Error(w, "Basic Pre-Authentication required.", http.StatusUnauthorized)
			return
		}

		if "GET" != r.Method {
			http.Error(w, "All API methods are GET requests, even when good REST habits suggest they should use a different verb.", http.StatusMethodNotAllowed)
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

		// https://stackoverflow.com/a/18414432
		options := cookiejar.Options{
			PublicSuffixList: publicsuffix.List,
		}
		jar, err := cookiejar.New(&options)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		client := http.Client{Jar: jar}

		resp, err := client.Get(base.String())
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
		formLogi.Set("returnurl", r.URL.String())
		resp, err = client.PostForm(resp.Request.URL.String(), formLogi)
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

		t, err := time.Parse("2006-01-02_150405", formLink.Get("lf_linkdate")) // rather ParseInLocation
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadGateway)
			return
		}

		w.Header().Set("Content-Type", "text/xml; charset=utf-8")

		rawText := func(s string) { io.WriteString(w, s) }
		xmlText := func(s string) { xml.EscapeText(w, []byte(s)) }
		xmlForm := func(s string) { xmlText(formLink.Get(s)) }

		rawText("<?xml version='1.0' encoding='UTF-8' ?>")
		rawText("<posts user='")
		xmlText(uid)
		rawText("' dt='")
		xmlText(time.Now().Format("2006-01-02"))
		rawText("' tag=''>")
		rawText("<post href='")
		xmlForm("lf_url")
		rawText("' hash='")
		xmlText("...id...")
		rawText("' description='")
		xmlForm("lf_title")
		rawText("' extended='")
		xmlForm("lf_description")
		rawText("' tag='")
		xmlForm("lf_tags")
		rawText("' time='")
		xmlText(t.Format(time.RFC3339))
		rawText("' others='")
		xmlText("0")
		rawText("' />")
		rawText("</posts>")

		return
	case "/v1/posts/recent":
	case "/v1/posts/dates":
	case "/v1/posts/suggest":
	case "/v1/tags/get":
	case "/v1/tags/delete":
	case "/v1/tags/rename":
	case "/v1/user/secret":
	case "/v1/user/api_token":
	case "/v1/notes/list":
	case "/v1/notes/ID":
		http.Error(w, "Not Implemented", http.StatusNotImplemented)
		return
	}
	http.NotFound(w, r)
}

func formValuesFromReader(r io.Reader, name string) (ret url.Values, err error) {
	root, err := html.Parse(r) // assumes r is UTF8
	if err != nil {
		return ret, err
	}

	for _, form := range scrape.FindAll(root, func(n *html.Node) bool { return atom.Form == n.DataAtom }) {
		if name != scrape.Attr(form, "name") && name != scrape.Attr(form, "id") {
			continue
		}
		ret := url.Values{}
		for _, inp := range scrape.FindAll(form, func(n *html.Node) bool { return atom.Input == n.DataAtom || atom.Textarea == n.DataAtom }) {
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
