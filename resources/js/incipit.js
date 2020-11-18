/*function myIncipit() {
    var input = this.data;
    var vrvToolkit = new verovio.toolkit();
              /\* Load the file using a HTTP GET *\/
              $.get(input, function( data ) {
                var svg = vrvToolkit.renderData(data.getElementsByTagName("score"), {});
                $("#incipitVerovio").html(svg);
              }, 'text');
}*/

/* 
* function myIncipit() {
*    var vrvToolkit = new verovio.toolkit();
*              $.ajax({
*                url: data(this)
*                , dataType: "text"
*               , success: function(data) {  
*                  var svg = vrvToolkit.renderData(data, {});
*                 $("#output-verovio").html(svg);
*            }
*       });
* }
*/

function myIncipit() {
    var input = "http://localhost:8080/exist/rest/db/apps/baudiWorks/data/baudi-02-40aa04e4_incip.xml" /* ?_query=//incip */
/*    var input = "https://www.verovio.org/editor/brahms.mei"*/
    return input;
}