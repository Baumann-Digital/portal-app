/* Filtern der Cards im Katalog nach Ampelsystem */
function ampel_rot() {
    if(document.getElementById("ampel_rot").checked) {
        for (let e of document.getElementsByName("created")) { e.style.display="block"; }
        }
    else {
        for (let e of document.getElementsByName("created")) { e.style.display="none"; }
        }
}

function ampel_gelb() {
   if(document.getElementById("ampel_gelb").checked) {
        for (let e of document.getElementsByName("checked")) { e.style.display="block"; }
        }
    else {
        for (let e of document.getElementsByName("checked")) { e.style.display="none"; }
        }
}

function ampel_gruen() {
if(document.getElementById("ampel_gruen").checked) {
        for (let e of document.getElementsByName("public")) { e.style.display="block"; }
        }
    else {
        for (let e of document.getElementsByName("public")) { e.style.display="none"; }
        }
}