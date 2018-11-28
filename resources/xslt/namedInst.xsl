<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" xpath-default-namespace="http://www.tei-c.org/ns/1.0" version="2.0">
    <xsl:output method="xhtml" encoding="UTF-8"/>
    <xsl:include href="linking.xsl"/>
    <xsl:template name="genannteInstitutionen" match="/">
        <xsl:for-each select="//div[@type = 'page' or @type = 'titlepage']//orgName[@key]/distinct-values(@key)">
            <xsl:sort select="lower-case(.)" data-type="text" order="ascending"/>
            <xsl:choose>
                <xsl:when test="doc-available(concat('../../../../contents/baudi/institutions/', ., '.xml'))">
                    <a href="{concat($registerRootPerson, .)}" target="_blank">
                        <xsl:value-of select="doc(concat('../../../../contents/baudi/institutions/', ., '.xml'))/TEI/teiHeader/fileDesc/titleStmt/title"/>
                    </a>
                    <br/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="normalize-space(.)"/>
                    <br/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
        <xsl:for-each select="//div[@type = 'page' or @type = 'titlepage']//orgName[not(@key)]/distinct-values(.)">
            <xsl:value-of select="normalize-space(.)"/>
            <br/>
        </xsl:for-each>
    </xsl:template>
</xsl:stylesheet>