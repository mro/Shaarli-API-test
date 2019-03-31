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
	"encoding/xml"
)

type Result struct {
	XMLName xml.Name `xml:"result"`
	Code    string   `xml:"code,attr,omitempty"`
}

type Post struct {
	Href        string `xml:"href,attr"`
	Description string `xml:"description,attr"`
	Extended    string `xml:"extended,attr"`
	Hash        string `xml:"hash,attr"`
	Meta        string `xml:"meta,attr,omitempty"`
	Others      int    `xml:"others,attr"`
	Tag         string `xml:"tag,attr"`
	Time        string `xml:"time,attr"`
}

type Posts struct {
	XMLName xml.Name `xml:"posts"`
	User    string   `xml:"user,attr"`
	Dt      string   `xml:"dt,attr"`
	Tag     string   `xml:"tag,attr"`
	Posts   []Post   `xml:"post"`
}
