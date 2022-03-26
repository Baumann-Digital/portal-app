xquery version "3.0";

import module namespace i18n = "http://exist-db.org/xquery/i18n" at "modules/i18n.xql";

import module namespace request = "http://exist-db.org/xquery/request";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

if ($exist:path eq '') then
    <dispatch
        xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect
            url="{request:get-uri()}/"/>
    </dispatch>

else
    if ($exist:path eq "/") then
        <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
            <redirect url="index.html"/>
        </dispatch>
        
        (: if it's a registry :)
    else
        if (matches($exist:path, "registry") or matches($exist:path, "about") or matches($exist:path, "view") or matches($exist:path, "imprint")) then
            <dispatch
                xmlns="http://exist.sourceforge.net/NS/exist">
                <forward
                    url="{$exist:controller}/templates/{$exist:resource}"/>
                <view>
                    <forward
                        url="{$exist:controller}/modules/view.xql"/>
                </view>
                <error-handler>
                    <forward
                        url="{$exist:controller}/templates/error-page.html"
                        method="get"/>
                    <forward
                        url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
            </dispatch>
            
            (: if it's a document :)
        else
            if (starts-with($exist:resource, "baudi-07-")) then
                <dispatch
                    xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward
                        url="{$exist:controller}/templates/viewDocument.html">
                        <add-parameter
                            name="document-id"
                            value="{$exist:resource}"/>
                    </forward>
                    <view>
                        <forward
                            url="{$exist:controller}/modules/view.xql">
                            <add-parameter
                                name="document-id"
                                value="{$exist:resource}"/>
                        </forward>
                    </view>
                    <error-handler>
                        <forward
                            url="{$exist:controller}/templates/error-page.html"
                            method="get"/>
                        <forward
                            url="{$exist:controller}/modules/view.xql"/>
                    </error-handler>
                </dispatch>
                
                (: if it's a person :)
            else
                if (starts-with($exist:resource, "baudi-04-")) then
                    <dispatch
                        xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward
                            url="{$exist:controller}/templates/viewPerson.html">
                            <add-parameter
                                name="person-id"
                                value="{$exist:resource}"/>
                        </forward>
                        <view>
                            <forward
                                url="{$exist:controller}/modules/view.xql">
                                <add-parameter
                                    name="person-id"
                                    value="{$exist:resource}"/>
                            </forward>
                        </view>
                        <error-handler>
                            <forward
                                url="{$exist:controller}/templates/error-page.html"
                                method="get"/>
                            <forward
                                url="{$exist:controller}/modules/view.xql"/>
                        </error-handler>
                    </dispatch>
                    
                    (: if it's a locus :)
                else
                    if (starts-with($exist:resource, "baudi-06-")) then
                        <dispatch
                            xmlns="http://exist.sourceforge.net/NS/exist">
                            <forward
                                url="{$exist:controller}/templates/viewLocus.html">
                                <add-parameter
                                    name="locus-id"
                                    value="{$exist:resource}"/>
                            </forward>
                            <view>
                                <forward
                                    url="{$exist:controller}/modules/view.xql">
                                    <add-parameter
                                        name="locus-id"
                                        value="{$exist:resource}"/>
                                </forward>
                            </view>
                            <error-handler>
                                <forward
                                    url="{$exist:controller}/templates/error-page.html"
                                    method="get"/>
                                <forward
                                    url="{$exist:controller}/modules/view.xql"/>
                            </error-handler>
                        </dispatch>
                        
                        (: if it's an institution :)
                    else
                        if (starts-with($exist:resource, "baudi-05-")) then
                            <dispatch
                                xmlns="http://exist.sourceforge.net/NS/exist">
                                <forward
                                    url="{$exist:controller}/templates/viewInstitution.html">
                                    <add-parameter
                                        name="institution-id"
                                        value="{$exist:resource}"/>
                                </forward>
                                <view>
                                    <forward
                                        url="{$exist:controller}/modules/view.xql">
                                        <add-parameter
                                            name="institution-id"
                                            value="{$exist:resource}"/>
                                    </forward>
                                </view>
                                <error-handler>
                                    <forward
                                        url="{$exist:controller}/templates/error-page.html"
                                        method="get"/>
                                    <forward
                                        url="{$exist:controller}/modules/view.xql"/>
                                </error-handler>
                            </dispatch>
                            
                            (: if it's a work :)
                        else
                            if (starts-with($exist:resource, "baudi-02-")) then
                                <dispatch
                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                    <forward
                                        url="{$exist:controller}/templates/viewWork.html">
                                        <add-parameter
                                            name="work-id"
                                            value="{$exist:resource}"/>
                                    </forward>
                                    <view>
                                        <forward
                                            url="{$exist:controller}/modules/view.xql">
                                            <add-parameter
                                                name="work-id"
                                                value="{$exist:resource}"/>
                                        </forward>
                                    </view>
                                    <error-handler>
                                        <forward
                                            url="{$exist:controller}/templates/error-page.html"
                                            method="get"/>
                                        <forward
                                            url="{$exist:controller}/modules/view.xql"/>
                                    </error-handler>
                                </dispatch>
                                
                                
                                (: if it's a musical source/manifestation :)
                            else
                                if (starts-with($exist:resource, "baudi-01-")) then
                                    (
                                    <dispatch
                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                        <forward
                                            url="{$exist:controller}/templates/viewSource.html">
                                            <add-parameter
                                                name="source-id"
                                                value="{$exist:resource}"/>
                                        </forward>
                                        
                                        <view>
                                            <forward
                                                url="{$exist:controller}/modules/view.xql">
                                                <add-parameter
                                                    name="source-id"
                                                    value="{$exist:resource}"/>
                                            </forward>
                                        </view>
                                        <error-handler>
                                            <forward
                                                url="{$exist:controller}/templates/error-page.html"
                                                method="get"/>
                                            <forward
                                                url="{$exist:controller}/modules/view.xql"/>
                                        </error-handler>
                                    </dispatch>
                                    
                                    )
                                    
                                    (: if it's a periodical :)
                                else
                                    if (starts-with($exist:resource, "baudi-09-")) then
                                        <dispatch
                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                            <forward
                                                url="{$exist:controller}/templates/viewPeriodical.html">
                                                <add-parameter
                                                    name="periodical-id"
                                                    value="{$exist:resource}"/>
                                            </forward>
                                            <view>
                                                <forward
                                                    url="{$exist:controller}/modules/view.xql">
                                                    <add-parameter
                                                        name="periodical-id"
                                                        value="{$exist:resource}"/>
                                                </forward>
                                            </view>
                                            <error-handler>
                                                <forward
                                                    url="{$exist:controller}/templates/error-page.html"
                                                    method="get"/>
                                                <forward
                                                    url="{$exist:controller}/modules/view.xql"/>
                                            </error-handler>
                                        </dispatch>
                                    else
                                    if (starts-with($exist:resource, "baudi-14-")) then
                                        <dispatch
                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                            <forward
                                                url="{$exist:controller}/templates/viewEdition.html">
                                                <add-parameter
                                                    name="edition-id"
                                                    value="{$exist:resource}"/>
                                            </forward>
                                            <view>
                                                <forward
                                                    url="{$exist:controller}/modules/view.xql">
                                                    <add-parameter
                                                        name="edition-id"
                                                        value="{$exist:resource}"/>
                                                </forward>
                                            </view>
                                            <error-handler>
                                                <forward
                                                    url="{$exist:controller}/templates/error-page.html"
                                                    method="get"/>
                                                <forward
                                                    url="{$exist:controller}/modules/view.xql"/>
                                            </error-handler>
                                        </dispatch>
                                    
                                    else
                                        if ($exist:path eq "/") then
                                            (: forward root path to index.xql :)
                                            <dispatch
                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                <redirect
                                                    url="index.html"/>
                                            </dispatch>
                                        
                                        else
                                            if (ends-with($exist:resource, ".html")) then
                                                (: the html page is run through view.xql to expand templates :)
                                                <dispatch
                                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                                    <view>
                                                        <forward
                                                            url="{$exist:controller}/modules/view.xql"/>
                                                    </view>
                                                    <error-handler>
                                                        <forward
                                                            url="{$exist:controller}/templates/error-page.html"
                                                            method="get"/>
                                                        <forward
                                                            url="{$exist:controller}/modules/view.xql"/>
                                                    </error-handler>
                                                </dispatch>
                                                (: Resource paths starting with $shared are loaded from the shared-resources app :)
                                            else
                                                if (contains($exist:path, "/$shared/")) then
                                                    <dispatch
                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                        <forward
                                                            url="/shared-resources/{substring-after($exist:path, '/$shared/')}">
                                                            <set-header
                                                                name="Cache-Control"
                                                                value="max-age=3600, must-revalidate"/>
                                                        </forward>
                                                    </dispatch>
                                                
                                                
                                                else
                                                    (: everything else is passed through :)
                                                    <dispatch
                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                        <cache-control
                                                            cache="yes"/>
                                                    </dispatch>

