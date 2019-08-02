
function myIncipit() {
    var vrvToolkit = new verovio.toolkit();
        /* Load the file using HTTP GET */
        $.get( "http://localhost:8080/exist/apps/baudi/html/sources/manuscript/", function( data ) {
            var svg = vrvToolkit.renderData(data, {});
            $("#output").html(svg);
        }, 'text');
    }