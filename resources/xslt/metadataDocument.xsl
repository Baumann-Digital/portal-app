<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" xpath-default-namespace="http://www.tei-c.org/ns/1.0" version="2.0">
    <xsl:output method="xhtml" encoding="UTF-8"/>
    <xsl:include href="linking.xsl"/>
    <xsl:template match="/">
        <br/>
        <table>
            <br/>
            <tr>
                <td>Titel:</td>
                <td>
                    <xsl:value-of select="//sourceDesc/bibl/title"/>
                    <xsl:choose>
                        <xsl:when test="doc-available(concat('../../../../contents/baudi/persons/', //sourceDesc/bibl/title/@key, '.xml'))">
                            <a href="{concat($dbRootParam, //sourceDesc/bibl/title/@key, '.html')}" target="_blank">
                                <xsl:value-of select="//sourceDesc/bibl/title"/>
                            </a>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="//sourceDesc/bibl/title"/>
                        </xsl:otherwise>
                    </xsl:choose>
                </td>
            </tr>
            <tr>
                <td>Autor:</td>
                <td>
                    <xsl:value-of select="//sourceDesc/bibl/author"/>
                </td>
            </tr>
            <tr>
                <td>Ort:</td>
                <td>
                    <xsl:value-of select="//sourceDesc/bibl/settlement"/>
                </td>
            </tr>
            <tr>
                <td>Datum:</td>
                <td>
                    <xsl:value-of select="//sourceDesc/bibl/date"/>
                </td>
            </tr>
            <tr>
                <td>Verlag:</td>
                <td>
                    <xsl:value-of select="//sourceDesc/bibl/publisher"/>
                </td>
            </tr>
            
            <tr>
                <td>Publikationsvermerk:</td>
                <td>
                    <xsl:value-of select="//publicationStmt/p"/>
                </td>
            </tr>
        </table>
    </xsl:template>
    
</xsl:stylesheet>