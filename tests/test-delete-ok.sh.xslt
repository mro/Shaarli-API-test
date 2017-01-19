<?xml version="1.0" encoding="UTF-8"?>
<!--

 Copyright (c) 2015-2016 Marcus Rohrmoser http://mro.name/me. All rights reserved.

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


 Find all 'delete_link' POST forms and list lf_linkdate and token.
 
 $ xsltproc - -html ../tests/test-delete-ok.sh.xslt curl.tmp.html

 http://www.w3.org/TR/xslt
-->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="xsl"
    version="1.0">
  <xsl:output method="text"/>

  <xsl:template match="/">
    <xsl:for-each select="html/body//form[.//input/@name='delete_link' and .//input/@name='lf_linkdate' and .//input/@name='token']">
      <xsl:variable name="lf_linkdate" select=".//input[@name='lf_linkdate']/@value"/>
      <xsl:variable name="token" select=".//input[@name='token']/@value"/>
      <xsl:value-of select="$lf_linkdate"/><xsl:text> </xsl:text><xsl:value-of select="$token"/><xsl:text>
</xsl:text>
    </xsl:for-each>
    <xsl:for-each select="html/body//a[contains(@href, '?delete_link=') and contains(@href, '&amp;token=')]">
      <xsl:variable name="lf_linkdate" select="substring-before(substring-after(@href,'?delete_link='), '&amp;token=')"/>
      <xsl:variable name="token" select="substring-after(@href,'&amp;token=')"/>
      <xsl:value-of select="$lf_linkdate"/><xsl:text> </xsl:text><xsl:value-of select="$token"/><xsl:text>
</xsl:text>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
