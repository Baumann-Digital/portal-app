<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <xsl:variable name="registerRootPerson" select="'html/person/'"/>
    <xsl:variable name="registerRootInstitution" select="'html/institution/'"/>
    <xsl:variable name="registerRootOrt" select="'html/place/'"/>
    <xsl:variable name="registerRootManuskript" select="'html/sources/manuscript/'"/>
    <xsl:variable name="registerRootDruck" select="'html/sources/print/'"/>
    <!--<xsl:variable name="LinkPerson">
        <xsl:choose>
            <xsl:when test="doc-available(concat('http://baumann-digital.de:8080/exist/contents/texts/persons/', ./@key, '.xml'))">
                <a href="{concat($registerRootPerson, ./@key, '.html')}" target="_blank">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:variable>-->
</xsl:stylesheet>