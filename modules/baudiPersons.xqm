xquery version "3.1";

module namespace baudiPersons="http://baumann-digital.de/ns/baudiPersons";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace mei="http://www.music-encoding.org/ns/mei";

import module namespace app="http://baumann-digital.de/ns/templates" at "/db/apps/baudiApp/modules/app.xql";

import module namespace baudiShared="http://baumann-digital.de/ns/baudiShared" at "/db/apps/baudiApp/modules/baudiShared.";
import module namespace templates="http://exist-db.org/xquery/html-templating";
import module namespace request="http://exist-db.org/xquery/request";

import module namespace functx="http://www.functx.com";
import module namespace json="http://www.json.org";
import module namespace jsonp="http://www.jsonp.org";

import module namespace i18n="http://exist-db.org/xquery/i18n" at "/db/apps/baudiApp/modules/i18n.xql";


declare function baudiPersons:getName($persId as xs:string, $type as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    return
        if ($type = 'uniform' or $type = 'reg')
        then (baudiPersons:getNameUniform($persId))
        else if ($type = 'full')
        then($person/tei:persName[@type = $type]//text() => string-join(' ' => normalize-space()))
        else()
};

declare function baudiPersons:getNameUniform($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $personName := if($person/tei:persName[@role='uniform' or @type='reg'])
                       then($person/tei:persName[@role='uniform' or @type='reg']//text() => string-join(' '))
                       else($person/tei:persName[1]//text() => string-join(' '))
    return
        $personName
};

declare function baudiPersons:getTitle($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $personTitle := $person//tei:addName[matches(@type,"title")]/text()
    return
        $personTitle
};

declare function baudiPersons:getFornames($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
        let $forenames := $person//tei:forename => distinct-values() => string-join(' ')
    return
        $forenames
};

declare function baudiPersons:getNameLink($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $nameLink := $person//tei:nameLink/text()
    return
        $nameLink
};

declare function baudiPersons:getSurnames($persId as xs:string, $type as xs:string?) {
    let $person := $app:collectionPersons/id($persId)
    let $persName := $person/tei:persName[(if($type != '') then(@type=$type) else(1))]
    let $surnames := $persName/tei:surname => string-join(' ')
    return
        $surnames
};

declare function baudiPersons:getGenName($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $genName := $person//tei:genName/text()
    return
        $genName
};

declare function baudiPersons:getEpithet($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $epithet := $person//tei:addName[matches(@type,"^epithet")]/text()
    return
        $epithet
};

declare function baudiPersons:getRoleName($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $roleNames := $person//tei:roleName/text() => string-join(' | ')
    return
        $roleNames
};

declare function baudiPersons:getNickName($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $nickName := $person//tei:addName[matches(@type,"^nick")] => string-join(' ')
    return
        $nickName
};

declare function baudiPersons:getPseudonym($persId as xs:string) {
(:    let $person := $app:collectionPersons/id($persId):)
(:    let $nickName := $person//tei:addName[matches(@type,"^nick")] => string-join(' '):)
(:    return:)
(:        $nickName:)
};

declare function baudiPersons:getNameUnspec($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $nameUnspec := $person//tei:name[matches(@type,'^unspecified')]/text()
    return
        $nameUnspec
};

declare function baudiPersons:getAffiliations($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $hasAffiliation := if($person//tei:affiliation[. != '']) then(true()) else(false())
    let $affiliations := <ul>{for $affiliation in $person//tei:affiliation[. != '']
                                return
                                    <li class="baudiListItem">{$affiliation/text()}</li>
                              }</ul>
    return
        if($hasAffiliation)
        then($affiliations)
        else()
};

declare function baudiPersons:getAffiliates($orgID as xs:string) {
    let $person := $app:collectionInstitutions/id($orgID)
    let $affiliatesColl := ($app:collectionPersons[matches(.//@key,$orgID)], $app:collectionInstitutions[matches(.//@key,$orgID)])
    let $hasAffiliates := if($affiliatesColl) then(true()) else(false())
    let $affiliates := <ul>{for $affiliate in $affiliatesColl
                                let $persName := if($affiliate/self::tei:person) then(baudiShared:getPersName($affiliate/@xml:id,'full','yes')) else()
                                let $orgName := if($affiliate/self::tei:org) then(baudiShared:getOrgNameFullLinked($affiliate/tei:org)) else()
                                return
                                    if($persName)
                                    then(<li class="baudiListItem">{$persName}</li>)
                                    else if ($orgName)
                                    then(<li class="baudiListItem">{$orgName}</li>) 
                                    else()
                              }</ul>
    return
        if($hasAffiliates)
        then($affiliates)
        else()
};

declare function baudiPersons:getOccupation($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    return
        if(if($person//tei:occupation[. != '']) then(true()) else(false()))
        then(<ul>{for $occupation in $person//tei:occupation[. != '']
                                return
                                    <li class="baudiListItem">{$occupation/text()}</li>
                              }</ul>)
        else()
};

declare function baudiPersons:getResidences($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    return
        if(if($person//tei:recidence[. != '']) then(true()) else(false()))
        then(<ul>{for $recidence in $person//tei:recidence[. != '']
                                return
                                    <li class="baudiListItem">{$recidence/text()}</li>
                              }</ul>)
        else()
};

declare function baudiPersons:getAnnotation($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    return
        if(if($person//tei:note[. != '']) then(true()) else(false()))
        then(<ul>{for $note in $person//tei:note[. != '']
                                return
                                    <li class="baudiListItem">{transform:transform($note,doc("/db/apps/baudiApp/resources/xslt/linking.xsl"), ())}</li>
                              }</ul>)
        else()
};

declare %private function baudiPersons:getBirth($person){
    if ($person//tei:birth[1][@when])
    then ($person//tei:birth[1]/@when)
    else if ($person//tei:birth[1][@when-iso])
    then ($person//tei:birth[1]/@when-iso)
    else if ($person//tei:birth[1][@notBefore] and $person//tei:birth[1][@notAfter])
    then (concat($person//tei:birth[1]/@notBefore, '/', $person//tei:birth[1]/@notAfter))
    else if ($person//tei:birth[1][@notBefore])
    then ($person//tei:birth[1]/@notBefore)
    else if ($person//tei:birth[1][@notAfter])
    then ($person//tei:birth[1]/@notAfter)
    else ('noBirth')
};
declare %private function baudiPersons:getDeath($person){
    if ($person//tei:death[1][@when])
    then ($person//tei:death[1]/@when)
    else if ($person//tei:death[1][@when-iso])
    then ($person//tei:death[1]/@when-iso)
    else if ($person//tei:death[1][@notBefore] and $person//tei:death[1][@notAfter])
    then (concat($person//tei:death[1]/@notBefore, '/', $person//tei:death[1]/@notAfter))
    else if ($person//tei:death[1][@notBefore])
    then ($person//tei:death[1]/@notBefore)
    else if ($person//tei:death[1][@notAfter])
    then ($person//tei:death[1]/@notAfter)
    else ('noDeath')
};

declare %private function baudiPersons:formatLifedata($lifedata){
if(starts-with($lifedata,'-')) then(concat(substring(string(number($lifedata)),2),' v. Chr.')) else($lifedata)
};

declare function baudiPersons:getLifeData($persId as xs:string) {
    let $lang := baudiShared:get-lang()
    let $person := $app:collectionPersons/id($persId)
    let $birth := if(baudiPersons:getBirth($person)='noBirth') then() else(baudiShared:formatDate(baudiPersons:getBirth($person), 'full', $lang))
    let $birthFormatted := baudiPersons:formatLifedata($birth)
    let $birthPlace := $person/tei:birth/tei:placeName//text() => string-join(' ') => normalize-space()
    let $death := if(baudiPersons:getDeath($person)='noDeath') then() else(baudiShared:formatDate(baudiPersons:getDeath($person), 'full', $lang))
    let $deathFormatted := if (contains($birthFormatted, ' v. Chr.') and not(contains(baudiPersons:formatLifedata($death), 'v. Chr.')))
                           then(concat(number(baudiPersons:formatLifedata($death)), ' n. Chr.'))
                           else (baudiPersons:formatLifedata($death))
    let $deathPlace := $person/tei:death/tei:placeName//text() => string-join(' ') => normalize-space()
    return
        if ($birthFormatted[. != ''] and $deathFormatted[. != ''])
        then (concat(' ', $birthFormatted, (if($birthPlace ) then(' (' || $birthPlace || ')') else()), '–', $deathFormatted, (if($deathPlace) then(' (' || $deathPlace || ')') else())))
        else if ($birthFormatted and not($deathFormatted))
        then (concat(' *', $birthFormatted, (if($birthPlace) then(' (' || $birthPlace || ')') else())))
        else if ($deathFormatted and not($birthFormatted))
        then (concat(' †', $deathFormatted, (if($deathPlace) then(' (' || $deathPlace || ')') else())))
        else ()
};
