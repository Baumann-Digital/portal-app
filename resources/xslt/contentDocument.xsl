<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" xpath-default-namespace="http://www.tei-c.org/ns/1.0" version="2.0">
    <xsl:output method="xhtml" encoding="UTF-8"/>
    <xsl:include href="formattingText.xsl"/>
    <xsl:template match="/">
        <link href="../css/dokument.css" rel="stylesheet" type="text/css"/>
        <br/>
        <br/>
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="div[@type = 'titlepage']">
        <div class="titlepage">
            <xsl:apply-templates/>
        </div>
    </xsl:template>
    
    <xsl:template match="table">
        <xsl:choose>
            <xsl:when test="exists(element(cb))">
                <table>
                    <tr>
                        <td valign="top">
                            <table>
                                <tr>
                                    <td>
                                        <xsl:for-each select="row[following-sibling::cb]">
                                            <tr>
                                                <xsl:choose>
                                                    <xsl:when test="cell[1][@rows]">
                                                        <xsl:variable name="rows" select="cell[1]/@rows/data(.)"/>
                                                        <td rowspan="{$rows}" class="rowspanned">
                                                            <xsl:value-of select="cell[1]"/>
                                                        </td>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <td>
                                                            <xsl:value-of select="cell[1]"/>
                                                        </td>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                                <xsl:choose>
                                                    <xsl:when test="cell[2][@rows]">
                                                        <xsl:variable name="rows" select="cell[2]/@rows/data(.)"/>
                                                        <td rowspan="{$rows}" class="rowspanned">
                                                            <img src="/resources/img/rightBracket.svg" height="55"/>
                                                            <xsl:value-of select="cell[2]"/>
                                                        </td>
                                                    </xsl:when>
                                                    <xsl:otherwise>
                                                        <td>
                                                            <xsl:value-of select="cell[2]"/>
                                                        </td>
                                                    </xsl:otherwise>
                                                </xsl:choose>
                                            </tr>
                                        </xsl:for-each>
                                    </td>
                                </tr>
                            </table>
                        </td>
                        <td valign="top">
                            <table>
                                <tr>
                                    <td>
                                        <xsl:for-each select="row[preceding-sibling::cb]">
                                            <tr>
                                                <td>
                                                    <xsl:value-of select="cell[1]"/>
                                                </td>
                                                <td>
                                                    <xsl:value-of select="cell[2]"/>
                                                </td>
                                            </tr>
                                        </xsl:for-each>
                                    </td>
                                </tr>
                            </table>
                        </td>
                    </tr>
                </table>
            </xsl:when>
            <xsl:when test="row/count(cell) = 8">
                <table>
                    <xsl:for-each select="row">
                        <tr>
                            <td>
                                <xsl:value-of select="cell[1]"/>
                            </td>
                            <td>
                                <xsl:value-of select="cell[2]"/>
                            </td>
                            <td>
                                <xsl:value-of select="cell[3]"/>
                            </td>
                            <td>
                                <xsl:value-of select="cell[4]"/>
                            </td>
                            <td>
                                <xsl:value-of select="cell[5]"/>
                            </td>
                            <td>
                                <xsl:value-of select="cell[6]"/>
                            </td>
                            <td>
                                <xsl:value-of select="cell[7]"/>
                            </td>
                            <td>
                                <xsl:value-of select="cell[8]"/>
                            </td>
                        </tr>
                    </xsl:for-each>
                </table>
            </xsl:when>
            <xsl:otherwise>
                <table>
                    <xsl:for-each select="row">
                        <tr>
                            <td>
                                <xsl:value-of select="cell[1]"/>
                            </td>
                            <td>
                                <xsl:value-of select="cell[2]"/>
                            </td>
                        </tr>
                    </xsl:for-each>
                </table>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>


</xsl:stylesheet>