<?xml version="1.0" encoding="UTF-8"?>
<!--

  This would be really nice to reduce the code-complexity of the (html) parser
  - if Apple wouldn't have chosen to consider libxslt a private API.
  http://stackoverflow.com/questions/7895157/applying-xslt-to-an-xml-coming-from-a-webservice-in-ios

  http://www.w3.org/TR/xslt


  Copyright (c) 2015 Marcus Rohrmoser http://mro.name/me. All rights reserved.

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

-->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="xsl"
    version="1.0">
  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="/">
    <shaarli>
      <!-- naked error message -->
      <xsl:for-each select="/html[1 = count(*)]/head[1 = count(*)]/script[starts-with(.,'alert(')]">
        <error message="{normalize-space(substring-before(substring-after(.,'alert(&quot;'), '&quot;'))}"/>
      </xsl:for-each>

      <xsl:for-each select="/html/body">
        <!-- embedded error message -->
        <xsl:for-each select="div[@id = 'pageheader']/div[@id='headerform' and 0 = count(*)]">
          <error message="{normalize-space(.)}"/>
        </xsl:for-each>

        <!-- shaarli title -->
        <xsl:for-each select="//span[@id = 'shaarli_title']">
          <xsl:attribute name="title">
            <xsl:value-of select="normalize-space(.)"/>
          </xsl:attribute>
        </xsl:for-each>

        <!-- logged in? -->
        <is_logged_in value="{1 = count(div[@id = 'pageheader']//a[@href = '?do=logout'])}"/>
        <!-- xsl:choose>
          <xsl:when test="1 = count(div[@id = 'pageheader']//a[@href = '?do=logout'])">
          </xsl:when>
          <xsl:otherwise>
            <is_logged_in value="false"/>
          </xsl:otherwise>
        </xsl:choose -->

        <!-- login and link form field presets and TOKEN -->
        <xsl:for-each select="//form[@name='loginform' or @name='linkform']">
          <xsl:copy>
            <xsl:for-each select="@* | .//input">
              <xsl:copy-of select="."/>
            </xsl:for-each>
          </xsl:copy>
        </xsl:for-each>

        <!-- tags from tagcloud (unused) -->
        <xsl:for-each select="//div[@id = 'cloudtag']/span[@class = 'count']">
          <tag count="{.}">
            <xsl:for-each select="following-sibling::a[1]">
              <xsl:attribute name="href">
                <xsl:value-of select="@href"/>
              </xsl:attribute>
              <xsl:attribute name="title">
                <xsl:value-of select="normalize-space(.)"/>
              </xsl:attribute>
            </xsl:for-each>
          </tag>
        </xsl:for-each>
      </xsl:for-each>
    </shaarli>
  </xsl:template>
</xsl:stylesheet>
