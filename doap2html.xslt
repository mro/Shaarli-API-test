<?xml version="1.0" encoding="UTF-8"?>
<!--

  Turn DOAP rdf into html.

  http://purl.mro.name/ios/ota
 
  Copyright (c) 2013-2015, Marcus Rohrmoser mobile Software
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, are permitted
  provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this list of conditions
  and the following disclaimer.

  2. The software must not be used for military or intelligence or related purposes nor
  anything that's in conflict with human rights as declared in http://www.un.org/en/documents/udhr/ .

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
  IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
  IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
  THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  http://www.w3.org/TR/xslt
  http://www.w3.org/TR/xpath/
-->
<xsl:stylesheet
   xmlns:dct="http://purl.org/dc/terms/"
   xmlns:doap="http://usefulinc.com/ns/doap#"
   xmlns:foaf="http://xmlns.com/foaf/0.1/"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns="http://www.w3.org/1999/xhtml"
   xmlns:date="http://exslt.org/date"
   version="1.0">
  <xsl:output
    method="html"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
    doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"/>

  <xsl:variable name="base_url" select="/*/@xml:base"/>

  <xsl:template match="/rdf:RDF">
    <xsl:apply-templates select="doap:Project[1]"/>
  </xsl:template>

  <xsl:template match="doap:Project">
    <html lang="en" xml:lang="en">
      <head>
        <meta name="viewport" content="width=320"/>
        <meta http-equiv="Content-type" content="text/html; charset=utf-8"/>
        <!-- meta charset="utf-8" / -->
        <link rel="shortcut icon" type="image/png" href="{foaf:img/@rdf:resource}"/>
        <link rel="stylesheet" type="text/css" media="screen" href="../ios-ota/screen.css"/>
        <!-- http://www.alexanderjaeger.de/webseite-mit-css-iphone-optimieren/ -->
        <link rel="stylesheet" type="text/css" media="only screen and (max-device-width: 480px)" href="../ios-ota/handheld.css"/>
        <title><xsl:value-of select="doap:name"/></title>
      </head>
      <body>
        <xsl:for-each select="/rdf:RDF/doap:Version[@rdf:about = current()/doap:release/@rdf:resource]">
          <!-- sort by doap:created, most recent only -->
          <xsl:sort select="doap:created" order="descending"/>
          <xsl:sort select="doap:revision" order="descending"/>
          <xsl:if test="position() = 1">
            <xsl:apply-templates mode="m_current_version" select="." />
          </xsl:if>
        </xsl:for-each>
        <h2>Interna</h2>
        <ul>
          <xsl:for-each select="doap:homepage/@rdf:resource">
            <li>
              <a href="{.}">Homepage</a>
            </li>
          </xsl:for-each>
          <xsl:for-each select="doap:bug-database/@rdf:resource[starts-with(.,'mailto:')]">
            <li>
              <a href="{.}">Bugreport via Email</a>
              <!-- http://www.redmine.org/projects/redmine/wiki/RedmineReceivingEmails -->
              <!-- http://www.cubetoon.com/2008/how-to-enter-line-break-into-mailto-body-command/ -->
            </li>
          </xsl:for-each>
          <xsl:for-each select="doap:bug-database/@rdf:resource[starts-with(.,'http:')]">
            <li><a href="{.}">Ticket System</a></li>
          </xsl:for-each>
        </ul>
        <h2>Alte Versionen</h2>
        <ul class="ipas" id="old">
          <xsl:for-each select="/rdf:RDF/doap:Version[@rdf:about = current()/doap:release/@rdf:resource]">
            <!-- sort by doap:created, all but most recent -->
            <xsl:sort select="doap:created" order="descending"/>
            <xsl:sort select="doap:revision" order="descending"/>
            <xsl:if test="position() > 1">
              <xsl:apply-templates select="." />
            </xsl:if>
          </xsl:for-each>
        </ul>
        <hr/>
        <!-- p><a href="http://validator.w3.org/check?uri=referer"><img src=
  "../assets/valid-xhtml10.png" alt="Valid XHTML 1.0 Strict" height="31" width=
  "88" /></a> <a href="http://jigsaw.w3.org/css-validator/check/referer"><img style=
  "border:0;width:88px;height:31px" src="../assets/vcss.png" alt=
  "CSS ist valide!" /></a></p -->
        <p id="poweredby" style="color:#888">
          Powered by <a href="https://github.com/mro/iOS-OTA">github.com/mro/iOS-OTA</a><br/>
          RDF (<a href="https://en.wikipedia.org/wiki/DOAP">DOAP</a>): <tt>$ <a href="http://librdf.org/raptor/rapper.html">rapper</a> --guess --output turtle
          '<span id="my-url"><xsl:value-of select="$base_url"/></span>'</tt>
        </p>
      </body>
    </html>
  </xsl:template>

  <xsl:template match="doap:Version" mode="m_current_version">
    <xsl:variable name="artwork_url" select="foaf:img/@rdf:resource"/>
    <xsl:variable name="manifest_url" select="concat($base_url, doap:file-release/@rdf:resource[contains(.,'/manifest.plist')])"/>
    <div id="header">
      <p style="float:left">
        <a href="itms-services://?action=download-manifest&amp;url={$manifest_url}" class="iTunesArtwork">
          <img src="{$artwork_url}" alt="Icon" class="iTunesArtwork"/>
          <img src="../ios-ota/iTunesArtwork-shine-512x512.svg" alt="artwork" class="iTunesArtworkMask"/>
        </a>
      </p>
      <p id="qr_code" style="float:right;background-color:white;padding:1.5ex">
        <!-- img src="https://chart.googleapis.com/chart?cht=qr&amp;chs=150x150&amp;chl={$base_url}" alt="QR Code" title="QR Code"/ -->
        <!-- img src="http://qrfree.kaywa.com/?l=1&amp;s=4&amp;d={$base_url}" alt="QR Code" title="QR Code"/ -->
      </p>
      <h1><xsl:value-of select="../doap:Project[1]/doap:name"/></h1>
    </div>
    <p style="float:none"/>
    <!-- h2>Current Version</h2 -->
    <ul class="ipas" id="current">
      <xsl:apply-templates select="."/>
    </ul>
  </xsl:template>

  <xsl:template match="doap:Version">
    <xsl:variable name="version" select="doap:revision"/>
    <xsl:variable name="date" select="translate(substring(doap:created, 1, 16), 'T', ' ')"/>
    <xsl:variable name="manifest_url" select="concat($base_url, doap:file-release/@rdf:resource[contains(.,'/manifest.plist')])"/>
    <xsl:variable name="docs_url" select="doap:specification/@rdf:resource"/>
    <xsl:variable name="zip_url" select="doap:file-release/@rdf:resource[contains(.,'.zip')]"/>
    <li>
      <a class="ota" href="itms-services://?action=download-manifest&amp;url={$manifest_url}">
        <xsl:value-of select="$version"/>
      </a>,
      <span class="date"><xsl:value-of select="$date"/>,&#10;</span>
      <xsl:if test="string-length($zip_url)">
        <span class="zip"><a href="{$zip_url}">zip</a>,&#10;</span>
      </xsl:if>
      <xsl:if test="string-length($docs_url)">
        <span class="docs"><a href="{$docs_url}">docs</a>,&#10;</span>
      </xsl:if>
    </li>
  </xsl:template>
</xsl:stylesheet>
