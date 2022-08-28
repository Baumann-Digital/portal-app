xquery version "3.0";

(:~
 : A set of helper functions to access the application context from
 : within a module.
:)
module namespace baudiVersions="http://baumann-digital.de/ns/versions";

import module namespace functx = "http://www.functx.com";

declare namespace templates="http://exist-db.org/xquery/html-templating";
declare namespace repo="http://exist-db.org/xquery/repo";
declare namespace expath="http://expath.org/ns/pkg";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

(: 
    Determine the application root collection from the current module load path.
:)

 
declare variable $baudiVersions:versions := 

let $historyDir := collection(concat($app:collStrTexts,'/portal/aboutBaumann.xml'
))

let $versions := $historyDir//tei:TEI (:tei:text/tei:body/tei:div[1]/tei:p[1]/tei:date[1]/string():)

let $versionsList := for $version in $versions
                        let $baseURI := base-uri($version)
                        let $versionName := substring(substring-after($baseURI,'.xml/'),1,10)
                        
                        order by $versionName ascending
                        return
                        <option>{$versionName}</option>
                            (:<option>{year-from-date(xs:date($versionName))}</option>:)
                            
let $versionsListMod := for $value at $pos in $versionsList
                            order by $pos descending
                            return
                            <option>{concat('V.',$pos,' (',year-from-date(xs:date($value)),'-',format-number(number(month-from-date(xs:date($value))),'00'),')')}</option>

return
<div class="form-group col-8">
    <label for="exampleFormControlSelect1">Historie</label>
    <select class="form-control" id="exampleFormControlSelect1">
      {$versionsListMod}
    </select>
  </div>
    
;
