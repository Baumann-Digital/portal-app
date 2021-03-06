<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xlink="http://www.w3.org/1999/xlink" version="2.0">
    <xsl:output method="xhtml" encoding="UTF-8"/>
    <xsl:template match="/">
        <div>
            <table border="0" width="100%">
                <tr>
                    <th/>
                    <th/>
                </tr>
                <!--<xsl:if test="not(//mei:titleStmt/mei:title[@type = 'uniform' and @xml:lang = 'de']/data(.) = '')">-->
                <tr>
                    <td>Besitzer:</td>
                    <td>
                        <xsl:value-of select="//mei:physLoc/mei:repository/mei:corpName"/> (<xsl:value-of select="//mei:physLoc/mei:repository/mei:corpName/@label"/>)</td>
                </tr>
                <!-- </xsl:if> -->
                <tr>
                    <td>Signatur:</td>
                    <td>
                        <xsl:value-of select="//mei:manifestationList/mei:manifestation/mei:physLoc//mei:identifier[@type='shelfmark']"/>
                    </td>
                </tr>
                <tr>
                    <td>RISM-Nr.:</td>
                    <td>
                        <xsl:value-of select="//mei:manifestationList/mei:manifestation/mei:identifier[@type='rism']"/>
                    </td>
                </tr>
                <tr>
                    <td valign="top">Beschreibung:</td>
                    <td>
                        <xsl:value-of select="//mei:physDesc/mei:physMedium"/>
                    </td>
                </tr>
                <xsl:if test="exists(//mei:titlePage)">
                    <tr>
                        <td>Titelseite:</td>
                        <td>
                            <xsl:call-template name="lineBreak"/>
                            <xsl:value-of select="//mei:titlePage/normalize-space()"/>
                       </td>
                    </tr>
                </xsl:if>
                <tr>
                    <td>Abmessungen:</td>
                    <td>
                        <xsl:value-of select="//mei:physDesc/mei:dimensions[@unit='mm']/mei:height"/> mm x <xsl:value-of select="//mei:physDesc/mei:dimensions[@unit='mm']/mei:width"/> mm (H x B)</td>
                </tr>
                <tr>
                    <td>Papierausrichtung:</td>
                    <td>
                        <xsl:choose>
                            <xsl:when test="//mei:physDesc/mei:extent[@label='orientation']='portrait'">Hochformat</xsl:when>
                            <xsl:when test="//mei:physDesc/mei:extent[@label='orientation']='landscape'">Querformat</xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="//mei:physDesc/mei:extent[@label='orientation']"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </td>
                </tr>
                <tr>
                    <td>
                        <xsl:choose>
                            <xsl:when test="//mei:physDesc/mei:extent[@label='folium']='1'">Folium</xsl:when>
                            <xsl:otherwise>Folii</xsl:otherwise>
                        </xsl:choose>
                    </td>
                    <td>
                        <xsl:value-of select="//mei:physDesc/mei:extent[@label='folium']"/>
                    </td>
                </tr>
                <tr>
                    <td>Notentext (Seiten)</td>
                    <td>
                        <xsl:value-of select="//mei:physDesc/mei:extent[@label='pages']"/>
                    </td>
                </tr>
                <tr>
                    <td>Seitenzählung:</td>
                    <td>
                        <xsl:choose>
                            <xsl:when test="//mei:physDesc/mei:extent[@label='pagination']/data(.)='none'">keine</xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="//mei:physDesc/mei:extent[@label='pagination']"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </td>
                </tr>
                <tr>
                    <td colspan="2">Handschriftliche Vermerke:</td>
                </tr>
                <tr>
                    <td colspan="2">
                        <ul style="list-style-type:circle">
                            <xsl:for-each select="//mei:physDesc/mei:handList/mei:hand">
                                <li>
                                    <i>
                                        <xsl:value-of select="."/>
                                    </i> (Medium: <xsl:value-of select="./@medium"/>; <xsl:value-of select="./@label"/>)</li>
                            </xsl:for-each>
                        </ul>
                    </td>
                </tr>
                <tr>
                    <td>Verwendetes Papier:</td>
                    <td>
                        <xsl:value-of select="//mei:notesStmt/mei:annot[@plist and contains(@plist,'paperTypeNote')]/normalize-space()"/> (Position: <xsl:value-of select="//mei:notesStmt/mei:annot[@plist]/@plist/substring-before(substring-after(.,' '),'-')"/>)</td>
                </tr>
                <tr>
                    <td>Stempel:</td>
                    <td>
                        <xsl:value-of select="//mei:notesStmt/mei:annot[@plist and contains(@plist,'stamp')]/normalize-space()"/> (Position: <xsl:value-of select="//mei:notesStmt/mei:annot[@plist]/@plist/substring-before(substring-after(.,' '),'-')"/>)</td>
                </tr>
                <tr>
                    <td>Sonst. Anmerkungen:</td>
                    <td>
                        <xsl:for-each select="//mei:notesStmt/mei:annot">
                            <li><xsl:value-of select="./normalize-space()"/></li>
                        </xsl:for-each>
                    </td>
                </tr>
                <tr>
                    <td>Art der Partitur:</td>
                    <td>
                        <xsl:choose>
                            <xsl:when test="//mei:scoreFormat/data(.)='song score'">Liedpartitur</xsl:when>
                            <xsl:when test="//mei:scoreFormat/data(.)='part'">Einzelstimme</xsl:when>
                            <xsl:when test="//mei:scoreFormat/data(.)='parts'">Stimmenmaterial</xsl:when>
                            <xsl:when test="//mei:scoreFormat/data(.)='orchestral score'">Orchesterpartitur</xsl:when>
                            <xsl:when test="//mei:scoreFormat/data(.)='piano score'">Klavierauszug</xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="//mei:scoreFormat"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </td>
                </tr>
                <tr>
                    <td>Sprache(n):</td>
                    <td>
                        <xsl:choose>
                            <xsl:when test="//mei:langUsage/mei:language/@label/data(.)='dt'">deutsch</xsl:when>
                            <xsl:when test="//mei:langUsage/mei:language/@label/data(.)='en'">englisch</xsl:when>
                            <xsl:when test="//mei:langUsage/mei:language/@label/data(.)='fr'">französisch</xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="//mei:langUsage/mei:language/@label"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </td>
                </tr>
                <xsl:if test="not(exists(//mei:term[@type='source' and @subtype='special' and contains(.,'Sammelquelle')]))">
                    <tr>
                        <td>Tonart:</td>
                        <td>
                            <xsl:choose>
                                <xsl:when test="//mei:workList/mei:work/mei:key/@mode/data(.)='minor'">
                                    <xsl:value-of select="lower-case(//mei:workList/mei:work/mei:key/@pname)"/>-Moll
                            </xsl:when>
                                <xsl:when test="//mei:workList/mei:work/mei:key/@mode/data(.)='major'">
                                    <xsl:value-of select="upper-case(//mei:workList/mei:work/mei:key/@pname)"/>-Dur
                            </xsl:when>
                                <xsl:when test="not(//mei:workList/mei:work/mei:key/@mode/data(.)='major') and not(//mei:workList/mei:work/mei:key/@mode/data(.)='minor')">
                                    <xsl:value-of select="lower-case(//mei:workList/mei:work/mei:key/@pname)"/>-<xsl:value-of select="//mei:workList/mei:work/mei:key/@mode"/>
                                </xsl:when>
                                <xsl:otherwise>
                               [unbekannt]
                            </xsl:otherwise>
                            </xsl:choose>
                        </td>
                    </tr>
                    <tr>
                        <td>Taktart:</td>
                        <td>
                            <xsl:value-of select="//mei:workList/mei:work/mei:meter/@count"/>/<xsl:value-of select="//mei:workList/mei:work/mei:meter/@unit"/>
                        </td>
                    </tr>
                    <xsl:if test="not(empty(mei:tempo))">
                        <tr>
                            <td>Tempobezeichnung:</td>
                            <td>
                                <xsl:value-of select="//mei:workList/mei:work/mei:tempo"/>
                            </td>
                        </tr>
                    </xsl:if>
                    </xsl:if>
                <xsl:if test="exists(//mei:term[@type='source' and @subtype='special' and contains(.,'Sammelquelle')])">
                    <tr>
                        <td colspan="2">Enthaltene Quellen:</td>
                    </tr>
                    <tr>
                        <td colspan="2">
                            <ul style="list-style-type:circle">
                                <xsl:for-each select="//mei:relationList/mei:relation">
                                    <li>
                                        (<xsl:value-of select="./@rel"/>)
                                        
                                        <xsl:choose>
                                            <xsl:when test="doc-available(concat('../../../contents/',./@target))">
                                                <a href="{concat('../baudi/html/sources/manuscript/',substring-before(substring-after(./@target,'music/'),'.xml'))}" target="_blank">
                                                    <xsl:value-of select="substring-before(substring-after(./@target,'music/'),'.xml')"/>
                                                </a>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of select="substring-before(substring-after(./@target,'music/'),'.xml')"/>
                                            </xsl:otherwise>
                                        </xsl:choose>
                                    </li>
                                </xsl:for-each>
                            </ul>
                        </td>
                    </tr>
                </xsl:if>
            </table>
        </div>
    </xsl:template>
    
    <xsl:template name="lineBreak">
        <xsl:if test="exists(lb)">
            <br/>
        </xsl:if>
    </xsl:template>
</xsl:stylesheet>