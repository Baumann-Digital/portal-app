<xsl:stylesheet xmlns="http://www.w3.org/1999/xhtml" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0" version="2.0" exclude-result-prefixes="#all">
    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl" scope="stylesheet" type="stylesheet">
        <desc>
            <p> TEI stylesheet dealing with elements from the linking module,
      making HTML output. </p>
            <p>This software is dual-licensed:

1. Distributed under a Creative Commons Attribution-ShareAlike 3.0
Unported License http://creativecommons.org/licenses/by-sa/3.0/ 

2. http://www.opensource.org/licenses/BSD-2-Clause
		


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

This software is provided by the copyright holders and contributors
"as is" and any express or implied warranties, including, but not
limited to, the implied warranties of merchantability and fitness for
a particular purpose are disclaimed. In no event shall the copyright
holder or contributors be liable for any direct, indirect, incidental,
special, exemplary, or consequential damages (including, but not
limited to, procurement of substitute goods or services; loss of use,
data, or profits; or business interruption) however caused and on any
theory of liability, whether in contract, strict liability, or tort
(including negligence or otherwise) arising in any way out of the use
of this software, even if advised of the possibility of such damage.
</p>
            <p>Author: See AUTHORS</p>
            <p>Copyright: 2013, TEI Consortium</p>
        </desc>
    </doc>
    <xsl:param name="linkElementNamespace">http://www.w3.org/1999/xhtml</xsl:param>
    <xsl:param name="linkAttributeNamespace"/>
    <doc xmlns="http://www.oxygenxml.com/ns/doc/xsl">
        <desc>Process element anchor</desc>
    </doc>
    <xsl:template match="tei:anchor">
        <xsl:call-template name="makeAnchor"/>
    </xsl:template>
<!--    RWA -->
    <xsl:template match="tei:ref[@rend = 'sup']">
        <xsl:element name="a">
            <xsl:attribute name="class">
                <xsl:value-of select="@rend"/>
            </xsl:attribute>
            <xsl:attribute name="id">
                <xsl:value-of select="@xml:id"/>
            </xsl:attribute>
            <xsl:attribute name="href">
                <xsl:value-of select="@target"/>
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:value-of select="."/>
            </xsl:attribute>
            <xsl:value-of select="."/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="tei:ref[@rend = 'readmore']">
        <xsl:element name="a">
            <xsl:attribute name="class">
                <xsl:value-of select="@rend"/>
            </xsl:attribute>
            <xsl:attribute name="id">
                <xsl:value-of select="@xml:id"/>
            </xsl:attribute>
            <xsl:attribute name="href">
                <xsl:value-of select="@target"/>
            </xsl:attribute>
            <xsl:attribute name="title">
                <xsl:value-of select="."/>
            </xsl:attribute>
            <small>
                <span aria-hidden="true" class="glyphicon glyphicon-new-window" data-original-title="Weitere Informationen…" data-placement="auto" data-toggle="tooltip"/>
            </small>
<!--            <xsl:value-of select="."/>-->
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>