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
	"fmt"
	"io/ioutil"
	"net/http"
	//	"net/http/cgi"
	"net/url"
	"os"
	"path"
	"path/filepath"
	"strings"

	"github.com/stretchr/testify/assert"
	"net/http/httptest"
	"testing"
)

func TestString(t *testing.T) {
	t.Parallel()
	const s = "abc"
	assert.Equal(t, "c", s[len(s)-1:], "ach")
}

func TestPath(t *testing.T) {
	t.Parallel()
	path_info := "pinboard4shaarli.cgi"
	base, _ := url.Parse("https://demo.shaarli.org/pinboard4shaarli.cgi/v1/about/")
	base.Path = path.Join(base.Path[0:len(base.Path)-len(path_info)], "..", "index.php")
	assert.Equal(t, "/index.php", base.Path, "ach")
	assert.Equal(t, "https://demo.shaarli.org/index.php", base.String(), "ach")

	cgi := filepath.Base("../uhu/pinboard4shaarli.cgi")
	str := "https://demo.shaarli.org/pinboard4shaarli.cgi/v1/about/"
	idx := strings.LastIndex(str, cgi)
	assert.Equal(t, "/v1/about/", str[idx+len(cgi):], "wowo")
}

func TestCgi(t *testing.T) {
	t.Parallel()

	// rq := httptest.NewRequest(http.MethodGet, "/", nil)
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, client, %s\n", r.URL.String())
	}))
	defer ts.Close()

	// assert.Equal(t, "", ts.Config, "wowo")
	// assert.Equal(t, "", ts.Config.Addr, "wowo")
	res, _ := http.Get(ts.URL + "/" + path.Join("pinboard4shaarli.cgi"))
	assert.Equal(t, http.StatusOK, res.StatusCode, "wowo")
	assert.Equal(t, int64(37), res.ContentLength, "wowo")
	assert.Equal(t, "text/plain; charset=utf-8", res.Header.Get("Content-Type"), "wowo")

	body, _ := ioutil.ReadAll(res.Body)
	res.Body.Close()
	assert.Equal(t, "Hello, client, /pinboard4shaarli.cgi\n", string(body), "wowo")
}

func TestBasicAuth(t *testing.T) {
	t.Parallel()
	url := "https://dema:demu@demo.shaarli.org/pinboard4shaarli.cgi/v1/posts/add?url=http://m.heise.de/12"
	r, err := http.NewRequest(http.MethodGet, url, nil)
	assert.Equal(t, nil, err, "wowo")
	usr := r.URL.User
	pwd, _ := usr.Password()
	r.SetBasicAuth(usr.Username(), pwd)
	uid, pwd, ok := r.BasicAuth()
	assert.Equal(t, true, ok, "wowo")
	assert.Equal(t, "dema", uid, "wowo")
	assert.Equal(t, "demu", pwd, "wowo")
}

func TestURL(t *testing.T) {
	t.Parallel()

	assert.Equal(t, "a/b", path.Join("a", "b", "/"), "ach")

	u, _ := url.Parse("https://l.mro.name/pinboard.cgi/v1/info")
	assert.Equal(t, "https://l.mro.name/pinboard.cgi/v1/info", u.String(), "ach")

	base := *u
	assert.Equal(t, "https://l.mro.name/pinboard.cgi/v1/info", base.String(), "ach")

	path_info := "/v1/info"
	base.Path = base.Path[0:len(base.Path)-len(path_info)] + "/../index.php"
	assert.Equal(t, "https://l.mro.name/pinboard.cgi/../index.php", base.String(), "ach")

	v := url.Values{}
	v.Set("post", "uhu")
	base.RawQuery = v.Encode()
	assert.Equal(t, "https://l.mro.name/pinboard.cgi/../index.php?post=uhu", base.String(), "ach")
}

func TestForm(t *testing.T) {
	t.Parallel()

	f := url.Values{}
	f.Set("login", "u i d")
	f.Set("password", "p & =d")
	r := bytes.NewReader([]byte(f.Encode()))
	b, err := ioutil.ReadAll(r)
	assert.Nil(t, err, "zzz")
	assert.Equal(t, "login=u+i+d&password=p+%26+%3Dd", string(b), "zzz")
}

func TestFormValuesFromHtml(t *testing.T) {
	file, err := os.Open("testdata/v0.10.2/login.html") // curl --location --output testdata/login.html 'https://demo.shaarli.org/?post=https://demo.mro.name/shaarligo'
	assert.Nil(t, err, "soso")
	ips, _ := formValuesFromReader(file, "loginform")
	assert.Equal(t, 40, len(ips["token"][0]), "form.token")
	// assert.Equal(t, "", ips["returnurl"][0], "form.returnurl")
	assert.Equal(t, "Login", ips[""][0], "form.")
	assert.Equal(t, "", ips["login"][0], "form.login")
	assert.Equal(t, "", ips["password"][0], "form.password")
	assert.Equal(t, "", ips["longlastingsession"][0], "form.longlastingsession")
	file.Close()

	file, err = os.Open("testdata/sebsauvage/login.html") // curl --location --output testdata/login.html 'https://demo.shaarli.org/?post=https://demo.mro.name/shaarligo'
	assert.Nil(t, err, "soso")
	ips, _ = formValuesFromReader(file, "loginform")
	assert.Equal(t, 40, len(ips["token"][0]), "form.token")
	// assert.Equal(t, "", ips["returnurl"][0], "form.returnurl")
	assert.Equal(t, "Login", ips[""][0], "form.")
	assert.Equal(t, "", ips["login"][0], "form.login")
	assert.Equal(t, "", ips["password"][0], "form.password")
	assert.Equal(t, "", ips["longlastingsession"][0], "form.longlastingsession")
	file.Close()

	file, err = os.Open("testdata/bookmark/login.html") // curl --location --output testdata/login.html 'https://demo.shaarli.org/?post=https://demo.mro.name/shaarligo'
	assert.Nil(t, err, "soso")
	ips, _ = formValuesFromReader(file, "loginform")
	assert.Equal(t, 40, len(ips["token"][0]), "form.token")
	// assert.Equal(t, "", ips["returnurl"][0], "form.returnurl")
	assert.Equal(t, "Login", ips[""][0], "form.")
	assert.Equal(t, "", ips["login"][0], "form.login")
	assert.Equal(t, "", ips["password"][0], "form.password")
	assert.Equal(t, "", ips["longlastingsession"][0], "form.longlastingsession")
	file.Close()

	file, err = os.Open("testdata/shaarligo/linkform.html") // curl --location --output testdata/login.html 'https://demo.shaarli.org/?post=https://demo.mro.name/shaarligo'
	assert.Nil(t, err, "soso")
	ips, _ = formValuesFromReader(file, "linkform")
	assert.Equal(t, 40, len(ips["token"][0]), "form.token")
	assert.Equal(t, "", ips["returnurl"][0], "form.returnurl")
	assert.Equal(t, "20190106_172531", ips["lf_linkdate"][0], "form.lf_linkdate")
	// tim, _ := time.ParseInLocation("20060102_150405", "20190106_172531", time.Now().Location())
	// assert.Equal(t, int64(1546791931), tim.Unix(), "form.lf_linkdate")
	// assert.Equal(t, time.Unix(1546791931, 0), tim, "form.lf_linkdate")
	assert.Equal(t, "", ips["lf_url"][0], "form.lf_url")
	assert.Equal(t, "uhu", ips["lf_title"][0], "form.lf_title")
	assert.Equal(t, "content", ips["lf_description"][0], "form.lf_description")
	assert.Equal(t, "", ips["lf_tags"][0], "form.lf_tags")
	assert.Equal(t, "Save", ips["save_edit"][0], "form.save_edit")
	file.Close()

	/*
	   	<?xml version="1.0" encoding="UTF-8"?>
	   <?xml-stylesheet type='text/xsl' href='./assets/default/de/do-post.xslt'?>
	   <!--
	     must be compatible with https://code.mro.name/mro/Shaarli-API-test/src/master/tests/test-post.sh
	     https://code.mro.name/mro/ShaarliOS/src/1d124e012933d1209d64071a90237dc5ec6372fc/ios/ShaarliOS/API/ShaarliCmd.m#L386
	   -->
	   <html xmlns="http://www.w3.org/1999/xhtml" xml:base="https://l.mro.name/">
	   <head><title>{ 🔗 🐳 🚀 💫  }</title></head>
	   <body>
	     <ul id="taglist" style="display:none"></ul>
	     <form method="post" name="linkform">
	       <input name="lf_linkdate" type="hidden" value="20190106_172531"/>
	       <input name="lf_url" type="text" value=""/>
	       <input name="lf_title" type="text" value="uhu"/>
	       <textarea name="lf_description" rows="4" cols="25"></textarea>
	       <input name="lf_tags" type="text" data-multiple="data-multiple" value=""/>
	       <input name="lf_private" type="checkbox" value=""/>
	       <input name="save_edit" type="submit" value="Save"/>
	       <input name="cancel_edit" type="submit" value="Cancel"/>
	       <input name="token" type="hidden" value="d9aab65f6ca2462449079d72d5321ebae0ec8325"/>
	       <input name="returnurl" type="hidden" value=""/>
	       <input name="lf_image" type="hidden" value=""/>
	     </form>
	   </body>
	   </html>
	*/
}

func TestRailRoad(t *testing.T) {
	fa := func(success bool) (ret string, err error) {
		if !success {
			return "fail", fmt.Errorf("failure")
		}
		return "ok", err
	}
	fb := func(s string, err0 error) (int, error) {
		if err0 != nil {
			return 0, err0
		}
		ret := 1
		if s == "ok" {
			ret = 2
		}
		return ret, err0
	}
	{
		v, e := fb(fa(true))
		assert.Equal(t, 2, v, "success")
		assert.Equal(t, nil, e, "success")
	}
	{
		v, e := fb(fa(false))
		assert.Equal(t, 0, v, "success")
		assert.Equal(t, "failure", e.Error(), "success")
	}
}
