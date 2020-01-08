<xsl:stylesheet xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    <xsl:variable name="viewPerson" select="'http://localhost:8080/exist/apps/baudi/html/person/'"/>
    <xsl:variable name="viewInstitution" select="'http://localhost:8080/exist/apps/baudi/html/institution/'"/>
    <xsl:variable name="viewWork" select="'http://localhost:8080/exist/apps/baudi/html/work/'"/>
    <xsl:variable name="viewLocus" select="'http://localhost:8080/exist/apps/baudi/html/locus/'"/>
    <xsl:variable name="viewManuscript" select="'http://localhost:8080/exist/apps/baudi/html/sources/manuscript/'"/>
    <xsl:variable name="viewPrint" select="'http://localhost:8080/exist/apps/baudi/html/sources/print/'"/>
    
    <!-- Linking persons -->
    <xsl:template match="tei:persName">
        <xsl:choose>
            <xsl:when test="doc-available(concat('/db/contents/baudi/persons/', ./@key, '.xml'))">
                <a href="{concat($viewPerson, ./@key)}">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mei:persName">
        <xsl:choose>
            <xsl:when test="doc-available(concat('/db/contents/baudi/persons/', ./@auth, '.xml'))">
                <a href="{concat($viewPerson, ./@auth)}">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- Linking institutions -->
    <xsl:template match="tei:orgName">
        <xsl:choose>
            <xsl:when test="doc-available(concat('/db/contents/baudi/institutions/', ./@key, '.xml'))">
                <a href="{concat($viewInstitution, ./@key)}">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mei:corpName">
        <xsl:choose>
            <xsl:when test="doc-available(concat('/db/contents/baudi/institutions/', ./@auth, '.xml'))">
                <a href="{concat($viewInstitution, ./@auth)}">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Linking works -->
    <xsl:template match="tei:title">
        <xsl:choose>
            <xsl:when test="doc-available(concat('/db/contents/baudi/works/', ./@key, '.xml'))">
                <a href="{concat($viewWork, ./@key)}">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="mei:title">
        <xsl:choose>
            <xsl:when test="doc-available(concat('/db/contents/baudi/works/', ./@auth, '.xml'))">
                <a href="{concat($viewWork, ./@auth)}">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Linking settlements -->
    <!--<xsl:template match="settlement">
        <xsl:choose>
            <xsl:when test="doc-available(concat('/db/contents/baudi/loci/', ./@key, '.xml'))">
                <a href="{concat($viewLocus, ./@key)}">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>-->
    
    
</xsl:stylesheet>