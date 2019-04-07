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
	"bufio"
	"bytes"
	"encoding/json"
	"encoding/xml"

	"github.com/stretchr/testify/assert"
	"testing"
)

// api_token {"result":"692D3D4BD4A2825D5A4A"}
// add {"result_code":"item already exists"}
// {"result_code":"done"}

// get {"date":"2018-04-09T19:26:54Z","user":"mro","posts":[]}

func xm(o interface{}) string {
	var b bytes.Buffer
	w := bufio.NewWriter(&b)
	enc := xml.NewEncoder(w)
	enc.Encode(o)
	enc.Flush()
	return string(b.Bytes())
}

func js(o interface{}) string {
	var b bytes.Buffer
	w := bufio.NewWriter(&b)
	enc := json.NewEncoder(w)
	enc.Encode(o)
	w.Flush()
	return string(b.Bytes())
}

func TestXmlEncodeResult(t *testing.T) {
	t.Parallel()
	r := Result{Code: "done"}
	assert.Equal(t, "<result code=\"done\"></result>", xm(r), "ach")
	assert.Equal(t, "{\"result_code\":\"done\"}\n", js(r), "ach")
}

func TestXmlEncodePosts(t *testing.T) {
	t.Parallel()

	assert.Equal(t, "<posts user=\"\" dt=\"\"><post href=\"uhu\" description=\"\" extended=\"\" hash=\"\" others=\"0\" tag=\"\" time=\"\"></post><post href=\"aha\" description=\"\" extended=\"\" hash=\"\" others=\"0\" tag=\"\" time=\"\"></post></posts>",
		xm(Posts{Posts: []Post{
			Post{Href: "uhu"},
			Post{Href: "aha"},
		}}), "ach")
	assert.Equal(t, "{\"user\":\"\",\"date\":\"\",\"posts\":[{\"href\":\"uhu\",\"description\":\"\",\"extended\":\"\",\"hash\":\"\",\"meta\":\"\",\"others\":0,\"tag\":\"\",\"time\":\"\"},{\"href\":\"aha\",\"description\":\"\",\"extended\":\"\",\"hash\":\"\",\"meta\":\"\",\"others\":0,\"tag\":\"\",\"time\":\"\"}]}\n",
		js(Posts{Posts: []Post{
			Post{Href: "uhu"},
			Post{Href: "aha"},
		}}), "ach")
}
