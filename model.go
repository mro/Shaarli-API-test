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
	XMLName xml.Name `xml:"result" json:"-"`
	Code    string   `xml:"code,attr,omitempty" json:"result_code"`
}

type Post struct {
	Href        string `xml:"href,attr" json:"href"`
	Description string `xml:"description,attr" json:"description"`
	Extended    string `xml:"extended,attr" json:"extended"`
	Hash        string `xml:"hash,attr" json:"hash"`
	Meta        string `xml:"meta,attr,omitempty" json:"meta"`
	Others      int    `xml:"others,attr" json:"others"`
	Tag         string `xml:"tag,attr" json:"tag"`
	Time        string `xml:"time,attr" json:"time"`
	Shared      string `xml:"shared,attr,omitempty" json:"shared,omitempty"`
	Toread      string `xml:"toread,attr,omitempty" json:"toread,omitempty"`
}

type Posts struct {
	XMLName xml.Name `xml:"posts" json:"-"`
	User    string   `xml:"user,attr" json:"user"`
	Dt      string   `xml:"dt,attr" json:"date"`
	Tag     string   `xml:"tag,attr,omitempty" json:"tag,omitempty"`
	Posts   []Post   `xml:"post" json:"posts"`
}
