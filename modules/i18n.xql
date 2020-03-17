module namespace i18n = 'http://exist-db.org/xquery/i18n';
(:~
    : I18N Internationalization Module

    : @author Lars Windauer <lars.windauer@betterform.de>
    : @author Tobias Krebs <tobi.krebs@betterform.de>
:)

(:~
 : Start processing the provided content using the modules defined by $modules. $modules should
 : be an XML fragment following the scheme:
 :
 : <modules>
 :       <module prefix="module-prefix" uri="module-uri" at="module location relative to apps module collection"/>
 : </modules>
 :
 : @param $content the sequence of nodes which will be processed
 : @param $modules modules to import
 : @param $model a sequence of items which will be passed to all called template functions. Use this to pass
 : information between templating instructions.
:)
declare function i18n:apply($content as node()+, $modules as element(modules), $model as item()*) {
    let $null := (
        request:set-attribute("$i18n:modules", $modules)
    )
    for $root in $content
        return
            i18n:process($root, (),(),())
};

(:~
 : Continue template processing on the given set of nodes. Call this function from
 : within other template functions to enable recursive processing of templates.
 :
 : @param $nodes the nodes to process
 : @param $model a sequence of items which will be passed to all called template functions. Use this to pass
 : information between templating instructions.
:)
declare function i18n:process($nodes as node()*, $selectedLang as xs:string,$pathToCatalogues as xs:string, $defaultLang as xs:string?) {
    for $node in $nodes
        let $selectedCatalogue := i18n:getLanguageCollection($nodes,$selectedLang, $pathToCatalogues,$defaultLang)
        return
            i18n:process($node, $selectedCatalogue)
};

(:~
 : recursive function to traverse through the document and to process all i18n prefixed nodes
 :
 : @param $node node to analyse if is an i18n:* node
 : @param $model a sequence of items which will be passed to all called template functions. Use this to pass
 : information between templating instructions.
:)
declare function i18n:process($node as node(), $selectedCatalogue as node()) {
    typeswitch ($node)
        case document-node() return
            for $child in $node/node() return i18n:process($child, $selectedCatalogue)

        case element(i18n:translate) return
            let $text := i18n:process($node/i18n:text,$selectedCatalogue)
            return
                i18n:translate($node, $text,$selectedCatalogue)

        case element(i18n:text) return
            i18n:getLocalizedText($node,$selectedCatalogue)

        case element() return
            element { node-name($node) } {
                    i18n:translateAttributes($node,$selectedCatalogue),
                    for $child in $node/node() return i18n:process($child,$selectedCatalogue)
            }

        default return
            $node
};

declare function i18n:translateAttributes($node as node(), $selectedCatalogue as node()){
    for $attribute in $node/@*
        return i18n:translateAttribute($attribute, $node, $selectedCatalogue)
};

declare function i18n:translateAttribute($attribute as attribute(), $node as node(),$selectedCatalogue as node()){
    if(starts-with($attribute, 'i18n(')) then
        let $key :=
            if(contains($attribute, ",")) then
                substring-before(substring-after($attribute,"i18n("),",")
            else
                substring-before(substring-after($attribute,"i18n("),")")
        let $i18nValue :=
            if(exists($selectedCatalogue//msg[@key eq $key])) then
                $selectedCatalogue//msg[@key eq $key]/text()
            else
                substring-before(substring-after(substring-after($attribute,"i18n("),","),")")
        return
            attribute {name($attribute)} {$i18nValue}
    else
        $attribute


};


(:
 : Get the localized value for a given key from the given catalogue
 : if no localized value is available, the default value is used
:)
declare function i18n:getLocalizedText($textNode as node(), $selectedCatalogue as node()){
    if(exists($selectedCatalogue//msg[@key eq $textNode/@key])) then
        $selectedCatalogue//msg[@key eq $textNode/@key]/text()
    else
        $textNode/text()

};

(:~
 : function implementing i18n:translate to enable localization of strings containing alphabetical or numerical parameters
 :
 : @param $node i18n:translate node enclosing i18n:text and parameters to substitute
 : @param $text the processed(!) content of i18n:text
:)
declare function i18n:translate($node as node(),$text as xs:string,$selectedCatalogue as node()) {
    if(contains($text,'{')) then
        (: text contains parameters to substitute :)
        let $params := $node//i18n:param
        let $paramKey := substring-before(substring-after($text, '{'),'}')
        return
            if(number($paramKey) and exists($params[position() eq number($paramKey)])) then
                (: numerical parameters to substituce :)
                let $selectedParam := $node/i18n:param[number($paramKey)]
                return
                    i18n:replaceParam($node, $selectedParam,$paramKey, $text,$selectedCatalogue)
            else if(exists($params[@key eq $paramKey])) then
                (: alphabetical parameters to substituce :)
                let $selectedParam := $params[@key eq $paramKey]
                return
                    i18n:replaceParam($node, $selectedParam,$paramKey, $text,$selectedCatalogue)

            else
                (: ERROR while processing parmaters to substitute:)
                concat("ERROR: Parameter ", $paramKey, " could not be substituted")
    else
        $text
};

(:~
 : function replacing the parameter with its (localized) value
 :
 : @param $node     i18n:translate node enclosing i18n:text and parameters to substitute
 : @param $param    currently processed i18n:param as node()
 : @param $paramKey currently processed parameterKey (numerical or alphabetical)
 : @param $text     the processed(!) content of i18n:text
:)
declare function i18n:replaceParam($node as node(), $param as node(),$paramKey as xs:string, $text as xs:string,$selectedCatalogue as node()) {
    if(exists($param/i18n:text)) then
        (: the parameter has to be translated as well :)
        let $translatedParam := i18n:getLocalizedText($param/i18n:text, $selectedCatalogue)
        let $result := replace($text, concat("\{", $paramKey, "\}"), $translatedParam)
        return i18n:translate($node,$result,$selectedCatalogue)
    else
        (: simply substitute {paramKey} with it's param value' :)
        let $result := replace($text, concat("\{", $paramKey, "\}"), $param)
        return
            i18n:translate($node, $result,$selectedCatalogue)
};

declare function i18n:getLanguageCollection($node as node()*,$selectedLang as xs:string,$pathToCatalogues as xs:string, $defaultLang as xs:string?) {
  let $tmpNode :=  typeswitch ($node)
        case document-node() return $node/node()
        default return $node

  let $lang := i18n:getSelectedLanguage($tmpNode,$selectedLang)
  let $cataloguePath := i18n:getPathToCatalogues($tmpNode,$pathToCatalogues)
  return
     if(exists(collection($cataloguePath)//catalogue[@xml:lang eq $lang])) then
        collection($cataloguePath)//catalogue[@xml:lang eq $lang]
    else if(string-length(request:get-parameter("defaultLang", "")) gt 0) then
        collection($cataloguePath)//catalogue[@xml:lang eq request:get-parameter("cataloguesPath", "")]
    else if(string-length($defaultLang) gt 0) then
        collection($cataloguePath)//catalogue[@xml:lang eq $defaultLang]
    else if(exists($tmpNode/@i18n:default-lang)) then
        collection($cataloguePath)//catalogue[@xml:lang eq $tmpNode/@i18n:default-lang]
    else ()

};

declare function i18n:getPathToCatalogues($node as node()*,$pathToCatalogues as xs:string){
    if(string-length($pathToCatalogues) gt 0) then
        $pathToCatalogues
    else if(string-length(request:get-parameter("cataloguesPath", "")) gt 0) then
        request:get-parameter("cataloguesPath", "")
    else if (exists($node/@i18n:catalogues)) then
        $node/@i18n:catalogues
    else 'ERROR: no path to language catalogues given'
};

(: Patrick integrates https://jaketrent.com/post/xquery-browser-language-detection/ :)

declare function local:get-browser-lang() as xs:string? {
  let $header := request:get-header("Accept-Language")
  return if (fn:exists($header)) then
    local:get-top-supported-lang(local:get-browser-langs($header), ("de", "en"))
  else
    ()
};

declare function local:get-top-supported-lang($ordered-langs as xs:string*, $translations as xs:string*) as xs:string? {
  if (fn:empty($ordered-langs)) then
    ()
  else
    let $lang := $ordered-langs[1]
    return if ($lang = $translations) then
      $lang
    else
      local:get-top-supported-lang(fn:subsequence($ordered-langs, 2), $translations)
};

declare function local:get-browser-langs($header as xs:string) as xs:string* {
  let $langs :=
    for $entry in fn:tokenize(local:parse-header($header), ",")
    let $data := fn:tokenize($entry, "q=")
    let $quality := $data[2]
    order by
      if (fn:exists($quality) and fn:string-length($quality) gt 0) then
  xs:float($quality)
      else
  xs:float(1.0)
      descending
    return $data[1]
  return $langs
};

declare function local:parse-header($header as xs:string) as xs:string {
  let $regex := "(([a-z]{1,8})(-[a-z]{1,8})?)\s*(;\s*q\s*=\s*(1|0\.[0-9]+))?"
  let $flags := "i"
  let $format := "$2q=$5"
  return fn:replace(fn:lower-case($header), $regex, $format)
};


declare function i18n:getSelectedLanguage($node as node()*,$selectedLang as xs:string) {
    if(string-length(request:get-parameter("lang", "")) gt 0) then
        (: use http parameter lang as selected language :)
        request:get-parameter("lang", "")
    (:
    else if(exists($node/@xml:lang)) then
        $node/@xml:lang
    else if(string-length($selectedLang) gt 0) then
        $selectedLang
    :)
    else
        local:get-browser-lang() (: Patrick did it! :)
};
