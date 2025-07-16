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

(:~
 : Returns the name of a person in a specified format.
 : @param $persId The person's unique identifier.
 : @param $type The type of name to return ('uniform', 'reg', or 'full').
 : @return The requested name as a string. If the value of $type is different from those specified here, an empty sequence is returned.
 :)
declare function baudiPersons:getName($persId as xs:string, $type as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    return
        if ($type = 'uniform' or $type = 'reg')
        then (baudiPersons:getNameUniform($persId))
        else if ($type = 'full')
        then($person/tei:persName[@type = $type]//text() => string-join(' ' => normalize-space()))
        else()
};

(:~
 : Returns the uniform name of a person.
 : @param $persId The person's unique identifier.
 : @return The uniform name as a string.
 :)
declare function baudiPersons:getNameUniform($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $personName := if($person/tei:persName[@role='uniform' or @type='reg'])
                       then($person/tei:persName[@role='uniform' or @type='reg']//text() => string-join(' '))
                       else($person/tei:persName[1]//text() => string-join(' '))
    return
        $personName
};

(:~
 : Returns the title(s) of a person.
 : @param $persId The person's unique identifier.
 : @return The title(s) as a string.
 :)
declare function baudiPersons:getTitle($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $personTitle := $person//tei:addName[matches(@type,"title")]/text()
    return
        $personTitle
};

(:~
 : Returns the forenames of a person.
 : @param $persId The person's unique identifier.
 : @return The forenames as a space-separated string.
 :)
declare function baudiPersons:getFornames($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
        let $forenames := $person//tei:forename => distinct-values() => string-join(' ')
    return
        $forenames
};

(:~
 : Returns the connecting phrase contained within a person's name.
 : @param $persId The person's unique identifier.
 : @return The phrase as a string, or an empty sequence if none is found.
 :)
declare function baudiPersons:getNameLink($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $nameLink := $person//tei:nameLink/text()
    return
        $nameLink
};

(:~
 : Returns the surname(s) of a person, optionally filtered by type.
 : @param $persId The person's unique identifier.
 : @param $type (optional) The type of name to filter by, as indicated by the tei:persName/@type attribute.
 : @return The surname(s) as a space-separated string.
 :)
declare function baudiPersons:getSurnames($persId as xs:string, $type as xs:string?) {
    let $person := $app:collectionPersons/id($persId)
    let $persName := $person/tei:persName[(if($type != '') then(@type=$type) else(1))]
    let $surnames := $persName/tei:surname => string-join(' ')
    return
        $surnames
};

(:~
 : Returns the generational name component (genName) of a person.
 : @param $persId The person's unique identifier.
 : @return The generational name component as a string.
 :)
declare function baudiPersons:getGenName($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $genName := $person//tei:genName/text()
    return
        $genName
};

(:~
 : Returns the epithet(s) of a person.
 : @param $persId The person's unique identifier.
 : @return The epithet(s) as a string.
 :)
declare function baudiPersons:getEpithet($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $epithet := $person//tei:addName[matches(@type,"^epithet")]/text()
    return
        $epithet
};

(:~
 : Returns the role name(s) of a person.
 : @param $persId The person's unique identifier.
 : @return The role name(s) as a pipe-separated string.
 :)
declare function baudiPersons:getRoleName($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $roleNames := $person//tei:roleName/text() => string-join(' | ')
    return
        $roleNames
};

(:~
 : Returns the nickname(s) of a person.
 : @param $persId The person's unique identifier.
 : @return The nickname(s) as a space-separated string.
 :)
declare function baudiPersons:getNickName($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $nickName := $person//tei:addName[matches(@type,"^nick")] => string-join(' ')
    return
        $nickName
};

(:~
 : Returns the pseudonym(s) of a person.
 : @param $persId The person's unique identifier.
 : @return The pseudonym(s) as a space-separated string (currently not implemented).
 :)
 (: ToDo: Implement pseudonym retrieval logic if needed :)
declare function baudiPersons:getPseudonym($persId as xs:string) {
(:    let $person := $app:collectionPersons/id($persId):)
(:    let $nickName := $person//tei:addName[matches(@type,"^nick")] => string-join(' '):)
(:    return:)
(:        $nickName:)
};

(:~
 : Returns the unspecified name(s) of a person (as indicated by a tei:name/@type value starting with 'unspecified').
 : @param $persId The person's unique identifier.
 : @return The unspecified name(s) as a string sequence.
 :)
declare function baudiPersons:getNameUnspec($persId as xs:string) {
    let $person := $app:collectionPersons/id($persId)
    let $nameUnspec := $person//tei:name[matches(@type,'^unspecified')]/text()
    return
        $nameUnspec
};

(:~
 : Returns the affiliations of a person as an HTML unordered list.
 : @param $persId The person's unique identifier.
 : @return An HTML <ul> element listing affiliations, or an empty sequence if none are found.
 :)
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

(:~
 : Returns the affiliates of an institution as an HTML unordered list, retrieved from the collections of persons and institutions alike.
 : @param $orgID The institution's unique identifier.
 : @return An HTML <ul> element listing affiliates, or an empty sequence if none are found.
 :)
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

(:~
 : Returns the occupation(s) of a person as an HTML unordered list.
 : @param $persId The person's unique identifier.
 : @return An HTML <ul> element listing occupations, or an empty sequence if none are found.
 :)
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

(:~
 : Returns the residence(s) of a person as an HTML unordered list.
 : @param $persId The person's unique identifier.
 : @return An HTML <ul> element listing residences, or an empty sequence if none are found.
 :)
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

(:~
 : Returns the annotation(s) (encoded as <tei:note> elements) stored in a person's record as an HTML unordered list.
 : @param $persId The person's unique identifier.
 : @return An HTML <ul> element containing HTML-formatted notes, or an empty sequence if the record does not contain any annotations.
 :)
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

(:~
 : Retrieves the birth date information from a <tei:person> node.
 : @param $person The <tei:person> node.
 : @return The birth date as a string in a normalized date format, or 'noBirth' if the node does not contain any processable attributes from the att.datable TEI class. Only the first encoded <tei:birth> element is regarded, and if a pair of @notBefore and @notAfter values is found, the output will contain both, separated by a '/' character.
 :)
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

(:~
 : Retrieves the death date information from a <tei:person> node.
 : @param $person The <tei:person> node.
 : @return The death date as a string in a normalized date format, or 'noDeath' if the node does not contain any processable attributes from the att.datable TEI class. Only the first encoded <tei:death> element is regarded, and if a pair of @notBefore and @notAfter values is found, the output will contain both, separated by a '/' character.
 :)
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

(:~
 : Formats strings containing life data (birth or death) for human-readable display, handling BCE dates.
 : @param $lifedata A normalized date string, with a leading '-' sign indicating a BCE date.
 : @return The formatted life data string, with the substring 'v. Chr.' indicating a BCE date.
 :)
declare %private function baudiPersons:formatLifedata($lifedata){
    if(starts-with($lifedata,'-')) 
    then(concat(substring(string(number($lifedata)),2),' v. Chr.')) else($lifedata)
};

(:~
 : Returns life data (dates and places of birth and death) of a person as a human-readable string.
 : @param $persId The person's unique identifier.
 : @return A string containing formatted birth and death data, including places if available, or an empty sequence if no information about either birth and death has been encoded.
 :)
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
