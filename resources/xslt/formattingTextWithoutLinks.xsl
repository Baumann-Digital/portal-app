<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" xpath-default-namespace="http://www.tei-c.org/ns/1.0" version="2.0">
    <xsl:output method="xhtml" encoding="UTF-8"/>
    <xsl:variable name="docID" select="//TEI/@xml:id/data(.)"/>
    <xsl:template match="p">
        <p>
            <xsl:apply-templates/>
        </p>
    </xsl:template>
    <xsl:template match="lb">
        <br/>
    </xsl:template>
    <xsl:template match="lb[@type='dipl']">
        <xsl:choose>
            <xsl:when test="@subtype='hyphen'">-<br class="dipl"/></xsl:when>
            <xsl:otherwise><br class="dipl"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <xsl:template match="pb">
        <xsl:choose>
            <xsl:when test="@subtype='hyphen'">-<hr/>
                <div class="text-muted text-center"><xsl:value-of select="@n"/></div>
                <hr/></xsl:when>
            <xsl:otherwise>
                <hr/>
                <div class="text-muted text-center"><xsl:value-of select="@n"/></div>
                <hr/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <xsl:template match="div/head">
        <b class="heading">
            <xsl:apply-templates/>
        </b>
    </xsl:template>
    <xsl:template match="body/head">
        <div class="page-header">
            <h1><xsl:apply-templates/></h1>
            <hr/>
        </div>
        
    </xsl:template>
    
    <xsl:template match="hi[@rend = 'bold']">
        <b>
            <xsl:apply-templates/>
        </b>
    </xsl:template>
    <xsl:template match="hi[@rend = 'italic']">
        <i>
            <xsl:apply-templates/>
        </i>
    </xsl:template>
    <xsl:template match="hi[contains(@rend,'underline')]">
        <span style="text-decoration: underline;">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="hi[@rend = 'strike']">
        <span class="text-decoration: line-through;">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="hi[@rend = 'overline']">
        <span class="text-decoration: overline;">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="hi[@rend = 'underover']">
        <span class="text-decoration: underline overline;">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <xsl:template match="node()[contains(@rend , 'left')]">
        <span class="text-left">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="node()[contains(@rend,'center')]">
        <span class="text-center">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="node()[contains(@rend ,'right')]">
        <span class="text-right">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="node()[contains(@rend , 'justify')]">
        <span class="text-justify">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    <xsl:template match="hi[@rend = 'code']">
        <span class="font-family: monospace, monospace; padding: 1rem; word-wrap: normal;">
            <xsl:apply-templates/>
        </span>
    </xsl:template>
    
    <xsl:template match="hi[contains(@rend,'heading1')]">
        <h1>
            <xsl:apply-templates/>
        </h1>
    </xsl:template>
    <xsl:template match="hi[contains(@rend,'heading3')]">
        <h3>
            <xsl:apply-templates/>
        </h3>
    </xsl:template>
    <xsl:template match="hi[contains(@rend,'heading5')]">
        <h5>
            <xsl:apply-templates/>
        </h5>
    </xsl:template>
    <xsl:template match="hi[contains(@rend,'sup')]">
        <sup>
            <xsl:apply-templates/>
        </sup>
    </xsl:template>
    <xsl:template match="hi[contains(@rend,'sub')]">
        <sub>
            <xsl:apply-templates/>
        </sub>
    </xsl:template>
    
    <xsl:template match="note[@type = 'editor']">
        [<i><xsl:apply-templates/></i>]
    </xsl:template>
    
    <xsl:template match="ref">
        <a href="{./@target}" target="_blank"><xsl:apply-templates/></a>
    </xsl:template>
    <xsl:template match="code">
        <pre><xsl:apply-templates/></pre>
    </xsl:template>

    <xsl:template match="figure">
        <xsl:variable name="picture" select="@facs"/>
        <p class="text-center">
            <img src="{$picture}" width="250"/>
        </p>
    </xsl:template>
    
    <xsl:template match="//choice">
        <xsl:for-each select=".">
            <xsl:variable name="expan" select="expan"/>
            <span class="abk" data-toggle="tooltip" data-placement="top" title="{$expan}">
                <xsl:value-of select="abbr"/>
            </span>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>