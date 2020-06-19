function myIncipit() {
    var input = this.data;
    var vrvToolkit = new verovio.toolkit();
              /* Load the file using a HTTP GET */
              $.get(input, function( data ) {
                var svg = vrvToolkit.renderData(data.getElementsByTagName("score"), {});
                $("#output").html(svg);
              }, 'text');
}

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