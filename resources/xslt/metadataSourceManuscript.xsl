<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xlink="http://www.w3.org/1999/xlink" version="2.0">
    <xsl:output method="xhtml" encoding="UTF-8"/>
    <xsl:template match="/">
        <div>
            <table border="0" width="100%">
                <tr>
                    <th/>
                    <th/>
                </tr>
                <xsl:if test="not(//mei:title[@type = 'uniform' and @xml:lang = 'de']/data(.) = '')">
                    <tr>
                        <td>Einheitstitel:</td>
                        <td>
                            <xsl:value-of select="//mei:title[@type = 'uniform' and @xml:lang = 'de']/mei:titlePart[@type='main']"/> <xsl:value-of select="//mei:title[@type = 'uniform' and @xml:lang = 'de']/mei:titlePart[@type='sub']"/>  <xsl:value-of select="//mei:title[@type = 'uniform' and @xml:lang = 'de']/mei:titlePart[@type='desc']"/> 
                        </td>
                    </tr>
                </xsl:if>
                <xsl:if test="not(//mei:titlePart[@type = 'main']/data(.) = '')">
                    <tr>
                        <td>Titel (diplomatisch):</td>
                        <td>
                            <xsl:value-of select="//mei:title[@type = 'main']"/>
                        </td>
                    </tr>
                </xsl:if>
                <xsl:if test="//mei:title[@type = 'subordinate']/text() != ''">
                    <tr>
                        <td>Untertitel (dipl.):</td>
                        <td>
                            <xsl:value-of select="//mei:title[@type = 'subordinate']"/>
                        </td>
                    </tr>
                </xsl:if>
                <xsl:if test="not(//mei:title[@type = 'desc']/data(.) = '')">
                    <tr>
                        <td>Besetzungsangabe:</td>
                        <td>
                            <xsl:value-of select="//mei:title[@type = 'uniform' and @xml:lang = 'de']/mei:titlePart[@type='desc']"/>
                        </td>
                    </tr>
                </xsl:if>
                <xsl:if test="not(exists(//mei:term[@type = 'source collection']))">
                    <xsl:if test="not(//mei:composer = '')">
                        <tr>
                            <td>Komponist:</td>
                            <td>
                                <xsl:value-of select="//mei:composer"/>
                            </td>
                        </tr>
                    </xsl:if>
                    <xsl:if test="not(//mei:lyricist = '')">
                        <tr>
                            <td>Textdichter:</td>
                            <td>
                                <xsl:value-of select="//mei:lyricist"/>
                            </td>
                        </tr>
                    </xsl:if>
                <tr>
                        <td valign="top">Besetzung:</td>
                        <td>
                            <ul>
                            <xsl:for-each select="//mei:perfMedium/mei:perfResList/mei:perfRes">
                                <xsl:sort select="." order="ascending" data-type="text"/>
                                <li>
                                    <xsl:variable name="auth" select="./@auth/string()"/>
                                    <xsl:value-of select="$auth"/>
                                    <xsl:if test="./@count &gt; 0">(<xsl:value-of select="./@count"/>) </xsl:if> 
                                </li>
                            </xsl:for-each>
                            </ul>
                        </td>
                    </tr>
                </xsl:if>
                <xsl:if test="exists(//mei:term[@type = 'source collection' ])">
                    <xsl:if test="not(//mei:composer = '')">
                        <tr>
                            <xsl:choose>
                                <xsl:when test="count(//mei:sourceDesc//mei:composer) &gt; 1">
                                    <td>Komponist(en):</td>
                                    <td>
                                        <xsl:for-each select="//mei:sourceDesc//mei:composer">
                                            <li>
                                                <xsl:value-of select="."/>
                                            </li>
                                        </xsl:for-each>
                                    </td>
                                </xsl:when>
                                <xsl:otherwise>
                                    <td>Komponist:</td>
                                    <td>
                                        <xsl:value-of select="//mei:sourceDesc//mei:composer"/>
                                    </td>
                                </xsl:otherwise>
                            </xsl:choose>
                        </tr>
                    </xsl:if>
                    <xsl:if test="not(//mei:lyricist = '')">
                        <tr>
                            <td>Textdichter:</td>
                            <xsl:choose>
                                <xsl:when test="count(//mei:sourceDesc//mei:lyricist) &gt; 1">
                                    <td>
                                        <xsl:for-each select="//mei:sourceDesc//mei:lyricist">
                                            <li>
                                                <xsl:value-of select="."/>
                                            </li>
                                        </xsl:for-each>
                                    </td>
                                </xsl:when>
                                <xsl:otherwise>
                                    <td>
                                        <xsl:value-of select="//mei:sourceDesc//mei:lyricist"/>
                                    </td>
                                </xsl:otherwise>
                            </xsl:choose>
                        </tr>
                    </xsl:if>
                </xsl:if>
            </table>
        </div>
    </xsl:template>
</xsl:stylesheet>