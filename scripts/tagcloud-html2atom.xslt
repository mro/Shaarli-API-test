<?xml version="1.0" encoding="UTF-8"?>
<!--

 $ curl "https://links.mro.name/?do=tagcloud" | xsltproc - -html tagcloud-html2atom.xslt - | xmllint - -relaxng categories.rng -

 http://www.w3.org/TR/xslt/
 http://www.w3.org/TR/xpath/
 https://tools.ietf.org/html/rfc5023#appendix-B
-->
<xsl:stylesheet
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:dctype="http://purl.org/dc/dcmitype/"
  xmlns="http://www.w3.org/2005/Atom"
  xmlns:app="http://www.w3.org/2007/app"
  xmlns:foo="foo"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  exclude-result-prefixes="dctype rdf"
  version="1.0">

  <xsl:output method="xml" indent="yes"/>

  <xsl:template match="/html">
    <xsl:comment>
  https://tools.ietf.org/html/rfc5023#appendix-B
  http://atomenabled.org/developers/protocol/#appCategories1
  https://web.archive.org/web/20130716150512/http://www.atomenabled.org:80/developers/protocol/atom-protocol-spec.php#rfc.section.8.3.3
  https://web.archive.org/web/20130716150512/http://www.atomenabled.org:80/developers/protocol/atom-protocol-spec.php#schema
</xsl:comment>
    <app:categories scheme="?searchtags=">
      <xsl:variable name="traditional_count_prefix" select="1 = count(.//a[starts-with(@href, '?searchtags=')][1]/preceding-sibling::*[1])"/>

      <xsl:for-each select=".//a[starts-with(@href, '?searchtags=')]">
        <xsl:sort select="." data-type="text" order="ascending"/>

        <xsl:variable name="count">
          <xsl:choose>
            <xsl:when test="$traditional_count_prefix"><xsl:value-of select="preceding-sibling::*[1]"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="following-sibling::*[1]"/></xsl:otherwise>
          </xsl:choose>
        </xsl:variable>

        <category term="{.}" foo:count="{$count}"/>
      </xsl:for-each>
    </app:categories>
  </xsl:template>

</xsl:stylesheet>
