/* Filtern der Cards im Katalog nach Ampelsystem */
function ampel_rot() {
    if(document.getElementById("ampel_rot").checked) {
        for (let e of document.getElementsByName("proposed")) { e.style.display="block"; }
        }
    else {
        for (let e of document.getElementsByName("proposed")) { e.style.display="none"; }
        }
}

function ampel_gelb() {
   if(document.getElementById("ampel_gelb").checked) {
        for (let e of document.getElementsByName("candidate")) { e.style.display="block"; }
        }
    else {
        for (let e of document.getElementsByName("candidate")) { e.style.display="none"; }
        }
}

function ampel_gruen() {
if(document.getElementById("ampel_gruen").checked) {
        for (let e of document.getElementsByName("approved")) { e.style.display="block"; }
        }
    else {
        for (let e of document.getElementsByName("approved")) { e.style.display="none"; }
        }
}