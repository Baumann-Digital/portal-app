/* Filtern der Cards im Katalog nach Ampelsystem */
function ampel_rot() {
    if(document.getElementById("ampel_rot").checked) {
        for (let e of document.getElementsByName("proposed")) { e.style.display="block"; }
        }
    else {
        for (let e of document.getElementsByName("proposed")) { e.style.display="none"; }
        }
    updateTabCounts();
    updateFilterCounts();
}

function ampel_gelb() {
   if(document.getElementById("ampel_gelb").checked) {
        for (let e of document.getElementsByName("candidate")) { e.style.display="block"; }
        }
    else {
        for (let e of document.getElementsByName("candidate")) { e.style.display="none"; }
        }
    updateTabCounts();
    updateFilterCounts();
}

function ampel_gruen() {
if(document.getElementById("ampel_gruen").checked) {
        for (let e of document.getElementsByName("approved")) { e.style.display="block"; }
        }
    else {
        for (let e of document.getElementsByName("approved")) { e.style.display="none"; }
        }
    updateTabCounts();
    updateFilterCounts();
}

/* Aktualisiert die Anzahl in den Tab-Navigationselementen basierend auf sichtbaren Karten */
function updateTabCounts() {
    // Finde alle Tab-Panes
    const tabPanes = document.querySelectorAll('.tab-content .tab-pane');
    
    tabPanes.forEach(pane => {
        const tabId = pane.id;
        if (!tabId) return;
        
        // Zähle alle sichtbaren Karten in diesem Tab
        const allCards = pane.querySelectorAll('.card');
        let count = 0;
        
        allCards.forEach(card => {
            // Eine Karte ist sichtbar, wenn sie nicht explizit versteckt ist
            if (card.style.display !== 'none') {
                count++;
            }
        });
        
        // Finde den entsprechenden Tab-Link
        const tabLink = document.querySelector(`a[href="#${tabId}"]`);
        if (tabLink) {
            // Ersetze die Zahl in Klammern am Ende des Textes
            tabLink.textContent = tabLink.textContent.replace(/\(\d+\)$/, `(${count})`);
        }
    });
}

/* Aktualisiert die Anzahl bei den Filter-Labels */
function updateFilterCounts() {
    // Zähle die Karten für jeden Status
    const filters = [
        { name: 'proposed', id: 'ampel_rot' },
        { name: 'candidate', id: 'ampel_gelb' },
        { name: 'approved', id: 'ampel_gruen' }
    ];
    
    filters.forEach(filter => {
        const cards = document.getElementsByName(filter.name);
        let visibleCount = 0;
        
        for (let card of cards) {
            // Eine Karte ist sichtbar, wenn sie nicht explizit auf 'none' gesetzt ist
            if (!card.style.display || card.style.display !== 'none') {
                visibleCount++;
            }
        }
        
        // Finde das Label und aktualisiere den Text
        const label = document.querySelector(`label[for="${filter.id}"]`);
        if (label) {
            // Entferne vorhandene Anzahl-Anzeige und füge neue hinzu
            const baseText = label.textContent.replace(/\s*\(\d+\)$/, '');
            label.textContent = `${baseText} (${visibleCount})`;
        }
    });
}

// Stelle sicher, dass die Counts beim Laden initialisiert werden
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function() {
        setTimeout(updateFilterCounts, 100);
    });
} else {
    // DOM ist bereits geladen
    setTimeout(updateFilterCounts, 100);
}