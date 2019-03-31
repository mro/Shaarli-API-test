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
	"encoding/xml"

	"github.com/stretchr/testify/assert"
	"testing"
)

func TestEncodeResult(t *testing.T) {
	t.Parallel()

	r := Result{Code: "done"}

	var b bytes.Buffer
	w := bufio.NewWriter(&b)
	enc := xml.NewEncoder(w)
	enc.Encode(r)
	enc.Flush()

	s := string(b.Bytes())
	assert.Equal(t, "<result code=\"done\"></result>", s, "ach")
}

func TestEncodePosts(t *testing.T) {
	t.Parallel()

	r := Posts{Posts: []Post{
		Post{Href: "uhu"},
		Post{Href: "aha"},
	}}

	var b bytes.Buffer
	w := bufio.NewWriter(&b)
	enc := xml.NewEncoder(w)
	enc.Encode(r)
	enc.Flush()

	s := string(b.Bytes())
	assert.Equal(t, "<posts user=\"\" dt=\"\" tag=\"\"><post href=\"uhu\" description=\"\" extended=\"\" hash=\"\" others=\"0\" tag=\"\" time=\"\"></post><post href=\"aha\" description=\"\" extended=\"\" hash=\"\" others=\"0\" tag=\"\" time=\"\"></post></posts>", s, "ach")
}
