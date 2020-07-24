<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xlink="http://www.w3.org/1999/xlink" version="2.0">
    <xsl:output method="xhtml" encoding="UTF-8" indent="yes"/>
    <xsl:include href="linking.xsl"/>
    <xsl:variable name="workID" select="./@xml:id"/>
    <xsl:template match="/">
        <div>
            <table border="0" width="100%">
                <tr>
                    <th/>
                    <th/>
                </tr>
                
                <xsl:if test="exists(//mei:title[@type='uniform']/mei:titlePart[@type = 'subordinate'])">
                    <tr>
                        <td>Untertitel:</td>
                        <td>
                            <xsl:value-of select="//mei:title[@type='uniform']/mei:titlePart[@type = 'subordinate']/text()"/>
                        </td>
                    </tr>
                </xsl:if>
                <xsl:if test="not(//mei:title[@type='uniform']/mei:titlePart[@type = 'perfmedium']/data(.) = '')">
                    <tr>
                        <td>Besetzung:</td>
                        <td>
                            <xsl:value-of select="//mei:title[@type='uniform']/mei:titlePart[@type = 'perfmedium']"/>
                        </td>
                    </tr>
                </xsl:if>
                <xsl:if test="//mei:titlePart[@type = 'mainAlt']/text() != ''">
                    <tr>
                        <td>Alternativer Titel:</td>
                        <td>
                            <xsl:value-of select="//mei:titlePart[@type = 'mainAlt']"/>
                        </td>
                    </tr>
                </xsl:if>
                <xsl:if test="//mei:titlePart[@type = 'subAlt']/text() != ''">
                    <tr>
                        <td>Alternativer Untertitel:</td>
                        <td>
                            <xsl:value-of select="//mei:title[@type='uniform']/mei:titlePart[@type = 'subAlt']"/>
                        </td>
                    </tr>
                </xsl:if>
                
                    <xsl:if test="not(//mei:composer/text() = '')">
                        <tr>
                            <td>Komponist</td>
                            <td><xsl:value-of select="//mei:composer"/></td>
                        </tr>
                    </xsl:if>
                    <xsl:if test="//mei:lyricist/text() != ''">
                        <tr>
                            <td>Textdichter:</td>
                            <td>
                                <xsl:value-of select="//mei:lyricist"/>
                            </td>
                        </tr>
                    </xsl:if>
                    <xsl:if test="//mei:langUsage/mei:language/@auth">
                        <tr>
                            <td>Sprache:</td>
                            <td>
                                <xsl:value-of select="//mei:langUsage/mei:language/@auth"/>
                            </td>
                        </tr>
                    </xsl:if>
                    <xsl:if test="//mei:term[@type='workGroup' and @subtype]">
                        <tr>
                            <td>Werkgruppe:</td>
                            <td>
                                <xsl:value-of select="//mei:term[@type='workGroup']/@subtype"/>
                            </td>
                        </tr>
                    </xsl:if>
                    <xsl:if test="//mei:term[@type='genre' and @subtype]">
                        <tr>
                            <td>Genre:</td>
                            <td>
                                <xsl:value-of select="//mei:term[@type='genre']/@subtype"/>
                            </td>
                        </tr>
                    </xsl:if>
                
                <xsl:if test="not(//mei:key/@mode/data(.) = '')">
                    <tr>
                        <td>Tonart:</td>
                        <td>
                            <xsl:choose>
                                <xsl:when test="//mei:key/@mode/data(.) = 'minor'">
                                    <xsl:value-of select="concat(lower-case(//mei:key/@pname),'-Moll')"/>
                                </xsl:when>
                                <xsl:when test="//mei:key/@mode/data(.) = 'major'">
                                    <xsl:value-of select="concat(upper-case(//mei:key/@pname),'-Dur')"/>
                                </xsl:when>
                                <xsl:when test="not(//mei:key/@mode/data(.) = 'major') and not(//mei:key/@mode/data(.) = 'minor')">
                                    <xsl:value-of select="lower-case(//mei:key/@pname)"/>-<xsl:value-of select="//mei:key/@mode"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    [unbekannt]
                                </xsl:otherwise>
                            </xsl:choose>
                        </td>
                    </tr>
                </xsl:if>
                <xsl:if test="not(//mei:meter/@count/data(.) = '')">
                    <tr>
                        <td>Taktart:</td>
                        <td>
                            <xsl:value-of select="//mei:meter/@count"/>/<xsl:value-of select="//mei:meter/@unit"/>
                            <xsl:choose>
                                <xsl:when test="//mei:meter/@sym = 'common'">&#160;<img src="/exist/apps/baudiApp/resources/img/timeSignature_common.png" width="20px"/></xsl:when>
                                <xsl:when test="//mei:meter/@sym = 'cut'">&#160;<img src="/exist/apps/baudiApp/resources/img/timeSignature_cut.png" width="20px"/></xsl:when>
                                <xsl:otherwise/>
                            </xsl:choose>
                        </td>
                    </tr>
                </xsl:if>
                <xsl:if test="not(empty(//mei:tempo))">
                    <tr>
                        <td>Tempobezeichnung:</td>
                        <td>
                            <xsl:value-of select="//mei:tempo/text()"/>
                        </td>
                    </tr>
                </xsl:if>
                <xsl:if test="not(//mei:persResList/data(.) = '')">
                    <tr>
                        <td valign="top">Beteiligte Instrumente:</td>
                        <td>
                            <xsl:for-each select="//mei:perfMedium/mei:perfResList/mei:perfRes/@auth">
<!--                                <xsl:sort select="." order="ascending" data-type="text"/>-->
                                <li style="list-style: square inside">
                                        <xsl:value-of select="."/>
                                        <xsl:if test="number(./@count) &gt; 0">(<xsl:value-of select="parent::node()/@count"/>)</xsl:if>
                                    
                                </li>
                            </xsl:for-each>
                        </td>
                    </tr>
                </xsl:if>
                <!--<xsl:if test="//mei:componentList/mei:manifestation/mei:title[@type='uniform']">
                <tr>
                    <td colspan="2">Zugehörige Quellen:</td>
                </tr>
                <tr>
                    <td colspan="2">
                        <ul style="list-style-type: square;">
                            <xsl:for-each select="collection('../../../baudiSources/data/music')//mei:mei">
                                <xsl:variable name="correspWork" select="//mei:relation/@target"/>
                                <xsl:if test="$correspWork=$workID">        
                                <li>
                                            <xsl:value-of select="//mei:titlePart[@type='main']/string()"/>
                                        </li>
                                </xsl:if>
                            </xsl:for-each>
                        </ul>
                    </td>
                </tr>
                </xsl:if>-->
                <xsl:if test="not(//mei:key/@mode/data(.) = '')"/>
            </table>
        </div>
    </xsl:template>
</xsl:stylesheet>