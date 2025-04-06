#target Illustrator

//  Updated: 2024.11.4, Aidan Van Vleck
//  Further documentation on the Skin CoRegistration protocol can be found in the YoLab - Current Projects Google drive. 
//  Google Drive Folder Path: YoLab - Current Projects/_Components and General Protocols/Skin CoRegistration Protocol/ Reference Protocol for Fluorescent Skin CoRegistration (XZ)
//  Link to Reference Protocol: https://docs.google.com/document/d/1-fYOJLyQK2c38IUVoarcfj_TPqYVu_sRxUwiC_I94dQ/edit?tab=t.0#heading=h.nw90t991hz9y

//  Script Description = Export layers from Illustrator as PNGs with the same name as the layer. It is called within Illustrator's File/Scripts menu. User can choose to select individual layers, all layers, or visible layers. Layers will be exported individually (all other layers made invisible)
//  Setting Script up for Use: This script must be run in an open document in Adobe Illustrator. This script must be placed within Adobe Illustrator's Presets/en_US/Scripts folder. This only needs to be done once, or whenever you need to update the script. 
//      Example: C:/ProgramFiles/Adobe/AdobeIllustrator2024/Presets/en_US/Scripts
//  Using the Script: 
//      Once you place this script in the folder above, open your file in Illustrator. 
//      Select the layers you want to export by making them visible (eyeball in the layers tab)
//      Click File/Scripts/exportLayersAsCSS_PNGs_2
//      Select if you want to export all layers (all), visible layers (visible), or specific layers (by name, eg. S2s1, S2s2)
//      Select your output folder


if (app.documents.length > 0) {
    main();
} else {
    alert('Cancelled by user');
}

function main() {
    var document = app.activeDocument;

    // Prompt user for export options
    var exportOption = prompt("Enter 'all' to export all layers, 'visible' for visible layers only, or specify layer names separated by commas:", "visible");

    var folder = document.fullName.parent.selectDlg("Select folder to export PNGs...");

    if (folder != null) {
        var activeABidx = document.artboards.getActiveArtboardIndex();
        var activeAB = document.artboards[activeABidx];
        var originalArtboardRect = activeAB.artboardRect;  // Store original artboard size

        var options = new ExportOptionsPNG24();
        options.antiAliasing = true;
        options.transparency = true;
        options.artBoardClipping = true;

        var layersToExport = getLayersToExport(exportOption);
        hideAllLayers();  // Hide all layers initially

        for (var i = 0; i < layersToExport.length; i++) {
            var layer = layersToExport[i];
            layer.visible = true;  // Show the current layer

            // Export the layer with the layer name
            var layerName = layer.name.replace(/[^\w\-\s]/gi, '');  // Sanitize file name
            var file = new File(folder.fsName + '/' + layerName + ".png");
            document.exportFile(file, ExportType.PNG24, options);

            layer.visible = false;  // Hide the layer after export
        }

        showAllLayers();  // Restore all layers visibility
        activeAB.artboardRect = originalArtboardRect;  // Reset artboard to original size
    }

    // Function to retrieve the list of layers to export based on user input
    function getLayersToExport(option) {
        var layers = [];
        switch (option.toLowerCase()) {
            case "all":
                layers = document.layers;
                break;
            case "visible":
                forEach(document.layers, function(layer) {
                    if (layer.visible) layers.push(layer);
                });
                break;
            default:
                var specificLayers = option.split(",").map(function(name) { return name.trim(); });
                forEach(document.layers, function(layer) {
                    if (specificLayers.indexOf(layer.name) > -1) layers.push(layer);
                });
                break;
        }
        return layers;
    }

    function hideAllLayers() {
        forEach(document.layers, function(layer) {
            layer.visible = false;
        });
    }

    function showAllLayers() {
        forEach(document.layers, function(layer) {
            layer.visible = true;
        });
    }

    function forEach(collection, fn) {
        var n = collection.length;
        for (var i = 0; i < n; ++i) {
            fn(collection[i]);
        }
    }
}
