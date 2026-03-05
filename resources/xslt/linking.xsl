<xsl:stylesheet xmlns:config="https://exist-db.org/xquery/config" xmlns:mei="http://www.music-encoding.org/ns/mei" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="2.0">
    
    <!-- Linking persons -->
    <xsl:template match="tei:persName">
        <xsl:choose>
            <xsl:when test="doc-available(concat(config:get-option('dataCollectionPath'), '/persons/', ./@key, '.xml'))">
                <a href="/{./@key}">
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
            <xsl:when test="doc-available(concat(config:get-option('dataCollectionPath'), '/persons/', ./@codedval, '.xml'))">
                <a href="/{./@codedval}">
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
            <xsl:when test="doc-available(concat(config:get-option('dataCollectionPath'), '/institutions/', ./@key, '.xml'))">
                <a href="/{./@key}">
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
            <xsl:when test="doc-available(concat(config:get-option('dataCollectionPath'), '/institutions/', ./@codedval, '.xml'))">
                <a href="/{./@codedval}">
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
            <xsl:when test="doc-available(concat(config:get-option('dataCollectionPath'), '/works/', ./@key, '.xml'))">
                <a href="/{./@key}">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- Linking settlements -->
    <xsl:template match="tei:settlement">
        <xsl:choose>
            <xsl:when test="doc-available(concat(config:get-option('dataCollectionPath'), '/loci/', ./@key, '.xml'))">
                <a href="/{./@key}">
                    <xsl:apply-templates/>
                </a>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <xsl:function name="config:get-option" as="xs:string?">
        <xsl:param name="option" as="xs:string"/>
        <xsl:value-of select="doc('/db/apps/baudiApp/catalogues/options.xml')//entry[@xml:id=$option]"/>
    </xsl:function>
    
</xsl:stylesheet>