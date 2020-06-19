xquery version "3.0";

declare namespace mei = "http://www.music-encoding.org/ns/mei";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace edirom = "http://www.edirom.de/ns/1.3";
declare namespace html="http://www.w3.org/1999/xhtml";

declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace functx = "http://www.functx.com";

let $templatePage := doc('/db/apps/baudiApp/templates/page.html')/html:html
let $placeForAlert := $templatePage//html:div[@id="content"]
let $alert := <div class="alert alert-info" role="alert">
                BauDi Development Area | eXistDB on http://localhost:8080
              </div>

  
  return
    (
      update insert $alert preceding $placeForAlert
    )
     