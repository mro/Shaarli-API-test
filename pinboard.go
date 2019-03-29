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

	if err := cgi.Serve(http.HandlerFunc(handleMux)); err != nil {
		log.Fatal(err)
	}
}

/// $ ./pinboard4shaarli.cgi --help | -h | -?
/// $ ./pinboard4shaarli.cgi https://demo.shaarli.org/pinboard4shaarli.cgi/v1/about/
/// $ ./pinboard4shaarli.cgi 'https://uid:pwd@demo.shaarli.org/pinboard4shaarli.cgi/v1/posts/get?url=http://m.heise.de/12'
/// $ ./pinboard4shaarli.cgi 'https://uid:pwd@demo.shaarli.org/pinboard4shaarli.cgi/v1/posts/add?url=http://m.heise.de/12&description=foo'
/// todo
/// $ ./pinboard4shaarli.cgi https://uid:pwd@demo.shaarli.org/pinboard4shaarli.cgi/v1/user/api_token
/// $ ./pinboard4shaarli.cgi https://demo.shaarli.org/pinboard4shaarli.cgi/v1/posts/get --auth_token=uid:XYZUUU --url=https://m.heise.de/foo
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
		os.Setenv("PATH_INFO", str[idx+len(bin):])
		handleMux(reqWri{r: req, f: os.Stderr, h: http.Header{}}, req)
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
func handleMux(w http.ResponseWriter, r *http.Request) {
	raw := func(s ...string) {
		for _, txt := range s {
			io.WriteString(w, txt)
		}
	}
	elmS := func(e string, close bool, atts ...string) {
		raw("<", e)
		for i, v := range atts {
			if i%2 == 0 {
				raw(" ", v, "=")
			} else {
				raw("'")
				xml.EscapeText(w, []byte(v))
				raw("'")
			}
		}
		if close {
			raw(" /")
		}
		raw(">", "\n")
	}
	elmE := func(e string) { raw("</", e, ">", "\n") }

	defer un(trace(strings.Join([]string{"v", version, "+", GitSHA1, " ", r.RemoteAddr, " ", r.Method, " ", r.URL.String()}, "")))
	path_info := os.Getenv("PATH_INFO")
	base := *r.URL
	base.Path = path.Join(base.Path[0:len(base.Path)-len(path_info)], "..", "index.php")

	w.Header().Set(http.CanonicalHeaderKey("X-Powered-By"), strings.Join([]string{"https://code.mro.name/mro/Shaarli-API-test", "#", version, "+", GitSHA1}, ""))
	w.Header().Set(http.CanonicalHeaderKey("Content-Type"), "text/xml; charset=utf-8")

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

	switch path_info {
	case "",
		"/about":
		base := *r.URL
		base.Path = path.Join(base.Path[0:len(base.Path)-len(path_info)], "about") + "/"
		http.Redirect(w, r, base.Path, http.StatusFound)

		return
	case "/about/":
		// w.Header().Set(http.CanonicalHeaderKey("Content-Type"), "application/rdf+xml")
		raw(`<?xml version="1.0" encoding="utf-8"?>
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns="http://usefulinc.com/ns/doap#">
  <Project>
    <name xml:lang="en">🛠 Pinboard API for Shaarlis</name>
    <short-description xml:lang="en">subset conforming https://pinboard.in/api/</short-description>
    <implements rdf:resource="https://pinboard.in/api/"/>
    <implements rdf:resource="https://code.mro.name/mro/pinboard4shaarli/src/develop/openapi.yaml"/>
    <platform rdf:resource="https://sebsauvage.net/wiki/doku.php?id=php:shaarli"/>
    <homepage rdf:resource="https://code.mro.name/mro/pinboard4shaarli/"/>
    <bug-database rdf:resource="https://code.mro.name/mro/pinboard4shaarli/issues"/>
    <wiki rdf:resource="https://code.mro.name/mro/pinboard4shaarli/wiki"/>
    <license rdf:resource="https://code.mro.name/mro/pinboard4shaarli/src/master/LICENSE"/>
    <maintainer rdf:resource="http://mro.name/~me"/>
    <programming-language>golang</programming-language>
    <category>microblogging</category>
    <category>shaarli</category>
    <category>nodb</category>
    <category>api</category>
    <category>pinboard</category>
    <category>delicious</category>
    <category>cgi</category>
    <repository>
      <GitRepository>
        <browse rdf:resource="https://code.mro.name/mro/pinboard4shaarli"/>
        <location rdf:resource="https://code.mro.name/mro/pinboard4shaarli.git"/>
      </GitRepository>
    </repository>
    <release>
      <Version>
        <name>`, version, "+", GitSHA1, `</name>
        <revision>`, GitSHA1, `</revision>
        <description>…</description>
      </Version>
    </release>
  </Project>
</rdf:RDF>`)

		return
	case "/v1/posts/add":
		// extract parameters
		// agent := r.Header.Get("User-Agent")
		shared := true

		uid, pwd, ok := r.BasicAuth()
		if !ok {
			http.Error(w, "Basic Pre-Authentication required.", http.StatusUnauthorized)
			return
		}

		if http.MethodGet != r.Method {
			w.Header().Set(http.CanonicalHeaderKey("Allow"), http.MethodGet)
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
		v.Set("title", p_description)
		base.RawQuery = v.Encode()

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

		resp, err = client.PostForm(resp.Request.URL.String(), formLink)
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadGateway)
			return
		}
		resp.Body.Close()

		raw(xml.Header)
		elmS("result", true,
			"code", "done")

		return
	case "/v1/posts/delete":
		_, _, ok := r.BasicAuth()
		if !ok {
			http.Error(w, "Basic Pre-Authentication required.", http.StatusUnauthorized)
			return
		}

		if http.MethodGet != r.Method {
			w.Header().Set(http.CanonicalHeaderKey("Allow"), http.MethodGet)
			http.Error(w, "All API methods are GET requests, even when good REST habits suggest they should use a different verb.", http.StatusMethodNotAllowed)
			return
		}

		params := r.URL.Query()
		if 1 != len(params["url"]) {
			http.Error(w, "Required parameter missing: url", http.StatusBadRequest)
			return
		}
		// p_url := params["url"][0]

		elmS("result", true,
			"code", "not implemented yet")
		return
	case "/v1/posts/update":
		_, _, ok := r.BasicAuth()
		if !ok {
			http.Error(w, "Basic Pre-Authentication required.", http.StatusUnauthorized)
			return
		}

		if http.MethodGet != r.Method {
			w.Header().Set(http.CanonicalHeaderKey("Allow"), http.MethodGet)
			http.Error(w, "All API methods are GET requests, even when good REST habits suggest they should use a different verb.", http.StatusMethodNotAllowed)
			return
		}

		raw(xml.Header)
		elmS("update", true,
			"time", "2011-03-24T19:02:07Z")
		return
	case "/v1/posts/get":
		// pretend to add, but don't actually do it, but return the form preset values.
		uid, pwd, ok := r.BasicAuth()
		if !ok {
			http.Error(w, "Basic Pre-Authentication required.", http.StatusUnauthorized)
			return
		}

		if http.MethodGet != r.Method {
			w.Header().Set(http.CanonicalHeaderKey("Allow"), http.MethodGet)
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

		fv := func(s string) string { return formLink.Get(s) }

		tim, err := time.ParseInLocation(ShaarliDate, fv("lf_linkdate"), time.Local) // can we do any better?
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadGateway)
			return
		}

		raw(xml.Header)
		elmS("posts", false,
			"user", uid,
			"dt", tim.Format(IsoDate),
			"tag", fv("lf_tags"))
		elmS("post", true,
			"href", fv("lf_url"),
			"hash", fv("lf_linkdate"),
			"description", fv("lf_title"),
			"extended", fv("lf_description"),
			"tag", fv("lf_tags"),
			"time", tim.Format(time.RFC3339),
			"others", "0")
		elmE("posts")

		return
	case "/v1/posts/recent",
		"/v1/posts/dates",
		"/v1/posts/suggest",
		"/v1/tags/get",
		"/v1/tags/delete",
		"/v1/tags/rename",
		"/v1/user/secret",
		"/v1/user/api_token",
		"/v1/notes/list",
		"/v1/notes/ID":
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
