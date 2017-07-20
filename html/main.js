var global_status = {};
global_status.plotted_projection = "";
global_status.plotted_signature = "";
global_status.sorted_column = "";
global_status.signature_filter = "";
global_status.scatterColorOption = "rank";
global_status.filter_group = "";
global_status.filter_group_genes = []

var global_data = {};
global_data.sigIsPrecomputed = {};

var global_options = {};
var global_scatter = {};
var global_heatmap = {};

// Keys are cluster methods
// Values are list of allowed method parameter
var cluster_options = { // Note: param values should be strings
    "KMeans": ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20"],
    //"PAM": ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"]
}

$(window).resize(function()
{
    $('#scatter_div').children().remove();
    global_scatter = new ColorScatter('#scatter_div', true);

    if($('#heatmap_div').is(":visible"))
    {
        $('#heatmap_div').find('svg').remove();
        global_heatmap = new HeatMap('#heatmap_div');
    } 

    if ($('#tree_div').is(":visible"))
	{ 
		$('#tree_div').find('svg').remove();
		global_tree = new TreeMap("#tree_div");
	}

    //Link the scatter/heatmap
    global_scatter.hovered_links.push(global_heatmap);
    global_heatmap.hovered_links.push(global_scatter);
    global_tree.hovered_links.push(global_tree);

    //Render
    drawChart();
    drawHeat();


});

function doneTyping()
{
    var val = global_status.signature_filter.toLowerCase();
    var vals = val.split(",");
    vals = vals.map(function(str){return str.trim();})
        .filter(function(str){ return str.length > 0;});

    var tablerows = $('#table_div table').find('tr');
    tablerows.removeClass('hidden');

    var posvals = vals.filter(function(str){ return str[0] != '!';});
    var negvals = vals.filter(function(str){ return str[0] == '!';})
        .map(function(str){ return str.slice(1);})
        .filter( function(str){return str.length > 0;});

    if(posvals.length > 0){
        tablerows.filter(function(i, element){
                if(i == 0){return false;} // Don't filter out the header row
                var sig_text = $(element).children('td').first().html().toLowerCase();
                for(var j = 0; j < posvals.length; j++)
                {
                    if(sig_text.indexOf(posvals[j]) > -1)
                    {
                        return false;
                    }
                }
                return true;
            }).addClass('hidden');
    }

    if(negvals.length > 0){
        tablerows.filter(function(i, element){
                if(i == 0){return false;} // Don't filter out the header row
                var sig_text = $(element).children('td').first().html().toLowerCase();
                for(var j = 0; j < negvals.length; j++)
                {
                    if(sig_text.indexOf(negvals[j]) > -1)
                    {
                        return true;
                    }
                }
                return false;
            }).addClass('hidden');
    }

    tablerows.removeClass('altRow')
            .not('.hidden').filter(':odd').addClass('altRow');
}

window.onload = function()
{

	tooltip = new Tooltip("main-tooltip", 230);

	$(".sigclust").on("mouseover", function(d) {
		tooltip.showTooltip("Click To Toggle Cluster Display", d);
	})
	.on("mouseout", function(d) {
		tooltip.hideTooltip();
	});


    //Define some globals
    global_scatter = new ColorScatter("#scatter_div", true);
    global_heatmap = new HeatMap("#heatmap_div");
    global_tree = new TreeMap("#tree_div");
    
    //Link the scatter/heatmap
    global_scatter.hovered_links.push(global_heatmap);
    global_heatmap.hovered_links.push(global_scatter);
	global_tree.hovered_links.push(global_scatter);
   
   	global_status.precomputed = false;


	var clusters_promise = api.signature.clusters(global_status.precomputed)
		.then(function(cls) {

		var clusarr = Object.keys( cls ).map(function ( key ) {return cls[key];});
		var clusmax = Math.max.apply(null, clusarr);

		for (curr_cl = 1; curr_cl <= clusmax; curr_cl++) {
			// Create new table and add to table_div
			var new_table_div = document.createElement("div");
			new_table_div.setAttribute("style", "height=calc((100vh - 88px) / 2)");
			new_table_div.setAttribute("class", "table_div");
			new_table_div.setAttribute("style", "overflow: hidden");

			var table_div_container = document.getElementById("table_div_container");

			var new_table = document.createElement("table");
			new_table.setAttribute("id", "table"+ curr_cl);
			new_table.setAttribute("class", "sig-cluster-table");

			var thead = document.createElement("thead");
			var tr = document.createElement("tr");
			var tr2 = document.createElement("tr");
			tr.setAttribute("id", "proj_row"+curr_cl);
			tr2.setAttribute("id", "summary_row"+curr_cl);
			tr2.setAttribute("class", "summary-row");
			thead.appendChild(tr);
			thead.appendChild(tr2);

			var tbody = document.createElement("tbody");
			
			new_table.appendChild(thead);
			new_table.appendChild(tbody);


			new_table_div.appendChild(new_table);
			table_div_container.appendChild(new_table_div);
			new_table_div.appendChild(document.createElement("br"));
		}

	});


    //Make the options update the table
    $("#filter_dropdown").change(function(){
        global_status.filter_group = $(this).val();

        api.filterGroup.genes(global_status.filter_group)
            .then(function(genes){
                global_status.filter_group_genes = genes;
                updateMenuBar();
            })

        // When this dropdown changes, everything should update
        createTableFromData().then(function(){
            // Needs to happen after createTableFromData because that function
            //   updates selected sig/proj
            drawChart();
            drawHeat();
            drawTree();
        });
    });

    var filterSig = $('#sig_filt_input');
    var filterSigTimer;
    var filterSigTimer_Timeout = 500;

    filterSig.on('input', function(){
        global_status.signature_filter = this.value;
        clearTimeout(filterSigTimer);
        filterSigTimer = setTimeout(doneTyping, filterSigTimer_Timeout);
    });

    // Define cluster dropdown 
    var clust_dropdown = $('#cluster_select_method');
    clust_dropdown.empty();
    $.each(cluster_options, function(name){
        clust_dropdown.append($("<option />").val(name).text(name));
    });
    clust_dropdown[0].selectedIndex = 0; // Restore index on model change

    build_cluster_dropdown_param = function()
    {
        // Rebuild the 'param' if the first dropdown is changed
        var vals = cluster_options[$('#cluster_select_method').val()]
        var clust_dropdown_param = $('#cluster_select_param');
        var old_val = clust_dropdown_param.val()

        clust_dropdown_param.empty();
        for(var i=0; i<vals.length; i++){
            clust_dropdown_param.append($("<option />").val(vals[i]).text(vals[i]));
        }

        if(vals.indexOf(old_val) > -1){
            clust_dropdown_param[0].selectedIndex = vals.indexOf(old_val)
        }
    }

    build_cluster_dropdown_param() // Call it now to initially populate it
    
    //Define cluster dropdown's change function
    $('#cluster_select_method').change(function(){
        build_cluster_dropdown_param()
        drawHeat();

    });

    //Define cluster dropdown's change function
    $('#cluster_select_param').change(function(){
        drawHeat();
    });

    //Define color option (for scatter) change function
    $('input[name=scatterColorButtons]').change(function(){
        var val = $('input[name=scatterColorButtons]:checked').val();
        global_status.scatterColorOption = val;
        drawChart();
    });

    // Make some service calls here
    // Get the list of filter groups
    var filterGroupPromise = api.filterGroup.list()
        .then(function(filters){

        for(var i = 0; i < filters.length; i++){
            filter = filters[i]
            var option = $(document.createElement("option"));
            option.text(filter).val(filter);
            $('#filter_dropdown').append(option);
        }

    });

    // Get the 'isPrecomputed' vector for signatures
    var sigIsPrecomputedPromise = api.signature.listPrecomputed()
        .then(function(sigIsPrecomputed) {
            global_data.sigIsPrecomputed = sigIsPrecomputed;
    });

    // When it's all done, run this
    $.when(filterGroupPromise, sigIsPrecomputedPromise)
        .then(function(){
        $("#filter_dropdown").change() // Change event updates the table
    });

	//$('input[type="radio"]:checked + label').css("border-bottom-color", "#eee");
};

Element.prototype.remove = function() {
	this.parentElement.removeChild(this);
}

function addSigClusterDivs() {

	$(".table_div").remove()

	var num_clusters_promise = api.signature.clusters(global_status.precomputed)
		.then(function(cls) {

		var clusarr = Object.keys( cls ).map(function ( key ) {return cls[key];});
		var clusmax = Math.max.apply(null, clusarr);

		for (curr_cl = 1; curr_cl <= clusmax; curr_cl++) {
			// Create new table and add to table_div
			var new_table_div = document.createElement("div");
			new_table_div.setAttribute("style", "height=calc((100vh - 88px) / 2)");
			new_table_div.setAttribute("id", "new_table_div");
			new_table_div.setAttribute("class", "table_div");


			var table_div_container = document.getElementById("table_div_container");

			var new_table = document.createElement("table");
			new_table.setAttribute("id", "table"+ curr_cl);
			new_table.setAttribute("class", "sig-cluster-table");

			var thead = document.createElement("thead");
			var tr = document.createElement("tr");
			var tr2 = document.createElement("tr");
			tr.setAttribute("id", "proj_row"+curr_cl);
			tr2.setAttribute("id", "summary_row"+curr_cl);
			thead.appendChild(tr);
			thead.appendChild(tr2);

			var tbody = document.createElement("tbody");
			
			new_table.appendChild(thead);
			new_table.appendChild(tbody);


			new_table_div.appendChild(new_table);
			table_div_container.appendChild(new_table_div);
			new_table_div.appendChild(document.createElement("br"));
		}

	});

}

function updateCurrentSelections(matrix)
{

    // If no sort specified, sort by PCA: 1,2
    if(matrix.proj_labels.indexOf(global_status.sorted_column) == -1 )
    {
        if(matrix.proj_labels.indexOf("PCA: 1,2" ) != -1){
            global_status.sorted_column = "PCA: 1,2";
        }
        else
        {
            global_status.sorted_column = "";
        }
    }

    // If no projection specified, select the PCA: 1,2 projection
    if(matrix.proj_labels.indexOf(global_status.plotted_projection) == -1)
    {
        if(matrix.proj_labels.indexOf("PCA: 1,2" ) != -1){
            global_status.plotted_projection = "PCA: 1,2";
        }
        else
        {
            global_status.plotted_projection = matrix.proj_labels[0];
        }
    }

    // If no signature specified, selected the top signature
    if(matrix.sig_labels.indexOf(global_status.plotted_signature) == -1)
    {
        //Select top signature of sorted projection by default
        var j = matrix.proj_labels.indexOf(global_status.plotted_projection);
        var s_i = matrix.data.map(function(e){return e[j];}).argSort();

        global_status.plotted_signature = matrix.sig_labels[s_i[0]];

    }
}

function updateMenuBar()  // Updates the ### Genes button in the menu bar
{
    var button = $('#show_genes_button');
    var num_genes = global_status.filter_group_genes.length
    button.text(num_genes + " Genes");
}

// Function that's triggered when clicking on table header column
function sortByColumn(col_name)  
{
    global_status.sorted_column = col_name;
    createTableFromData();
}

// Function that's triggered when clicking on table cell
function tableClickFunction(row_key, col_key)
{
    global_status.plotted_signature  = row_key;
    global_status.plotted_projection = col_key;
    drawChart();
    drawHeat();
    drawTree();
}

// Draw the scatter plot
function drawChart() {

    var sig_key = global_status.plotted_signature;
    var proj_key = global_status.plotted_projection;
    var filter_group = global_status.filter_group;

    if(sig_key.length == 0 && proj_key.length == 0){
        $('#plot-title').text("");
        $('#plot-subtitle').text("");
        global_scatter.setData([], false);
        return $().promise()
    }

    var proj_promise = api.projection.coordinates(filter_group, proj_key);

	var sig_promise;
    if(global_status.scatterColorOption == "value" || 
        global_data.sigIsPrecomputed[sig_key])
        {sig_promise = api.signature.scores(sig_key)}

    if(global_status.scatterColorOption == "rank") 
        {sig_promise = api.signature.ranks(sig_key)}

    var sig_info_promise = api.signature.info(sig_key)

    return $.when(proj_promise, sig_promise, sig_info_promise) // Runs when both are completed
        .then(function(projection, signature, sig_info){
            
			$('#plot-title').text(proj_key);
			$('#plot-subtitle').text(sig_key);

            var points = [];
            for(sample_label in signature){
                var x = projection[sample_label][0]
                var y = projection[sample_label][1]
                var sig_score = signature[sample_label]
                points.push([x, y, sig_score, sample_label]);
            }

            global_scatter.setData(points, sig_info.isFactor);

        });

}

// Draw the Tree
function drawTree() {
	var sig_key = global_status.plotted_signature;
	var proj_key = global_status.plotted_projection;
	var filter_group = global_status.filter_group;

	if (!$('#tree-options').hasClass('active')) {
		$("#tree_div").hide();
		$('#instructions').show();
		return;
	}
	$("#instructions").hide();
	if (sig_key.length == 0) {
		$('#tree_div').hide();
		return $().promise();
	}
	$("#tree_div rect").show();
	return $.when(api.signature.info(sig_key),
			api.signature.expression(sig_key),
			api.projection.tree(filter_group, proj_key))
				.then(function(sig_info, sig_expression, tree_data) {
			
			console.log(tree_data[3]);
			if (sig_info.isPrecomputed) {
				return;
			}

			if (!$('#tree_div').is(":visible"))
			{
				$("#tree_div").find("svg").remove();
				$("#tree_div").show();
				global_tree = new TreeMap("#tree_div", document);
				global_tree.hovered_links.push(global_scatter);
			}

			sample_labels = sig_expression.sample_labels;
			
			return global_tree.setData(tree_data[1], tree_data[3], sample_labels);
	});
}


// Draw the heatmap
function drawHeat(){
    var sig_key = global_status.plotted_signature;
    var proj_key = global_status.plotted_projection;
    var filter_group = global_status.filter_group
    var cluster_method = $('#cluster_select_method').val();
    var cluster_param = $('#cluster_select_param').val();

    if(sig_key.length == 0){
        $('#heatmap_div').hide();
        return $().promise();
    }

    $("#heatmap_div rect").show();
	return $.when(api.signature.info(sig_key),
		api.signature.expression(sig_key),
		api.projection.clusters(filter_group, proj_key, cluster_method, cluster_param))
			.then(function(sig_info, sig_expression, cluster){

			if(sig_info.isPrecomputed){
				$('#heatmap_div').hide();
				return
			}

			// Heatmap doesn't show for precomputed sigs
			// Need to recreate it if it isn't there
			if( !$('#heatmap_div').is(":visible"))
			{
				$('#heatmap_div').find('svg').remove();
				$('#heatmap_div').show();
				global_heatmap = new HeatMap('#heatmap_div');
				global_scatter.hovered_links.push(global_heatmap);
				global_heatmap.hovered_links.push(global_scatter);
			}
            

		//Construct data matrix
		// TODO: sort genes

		dataMat = sig_expression.data;
		gene_labels = sig_expression.gene_labels;
		sample_labels = sig_expression.sample_labels;

		var gene_signs = gene_labels.map(function(e,i){
			return sig_info.sigDict[e]
		});

		//var assignments = data.Clusters[proj_key][choice];
		var assignments = sample_labels.map(sample => cluster['data'][sample]);

		global_heatmap.setData(dataMat,
				assignments,
				gene_labels,
				gene_signs,
				sample_labels);

    });
}


function createTableFromData()
{

	addSigClusterDivs();
    return $.when(api.filterGroup.sigProjMatrixP(global_status.filter_group, global_status.precomputed),
					api.signature.clusters(global_status.precomputed))
        .then(function(matrix, cls){
        	

        var clusarr = Object.keys( cls ).map(function(key) { return cls[key]; });
        var clusmax = Math.max.apply(null, clusarr);
        updateCurrentSelections(matrix);

        // Detach filter sig box for later
        var filterSig = $('#sig_filt_input');
        filterSig.detach();


		for (curr_cl = 1; curr_cl <= clusmax; curr_cl++) {
			
			// Create the Header row
			var header_row = d3.select("#table"+curr_cl).select("thead").select("#proj_row"+curr_cl).selectAll("th")
				.data([""].concat(matrix.proj_labels));
	        header_row.enter().append('th');
		    header_row.html(function(d){return "<div>"+d+"</div>";})
			    .filter(function(d,i) {return i > 0;})
				.on("click", function(d,i) { sortByColumn(d);});

			header_row.exit().remove();

			if (typeof(matrix.sig_labels) == "string") {
				matrix.sig_labels = [matrix.sig_labels];
			}

			// Format cell data for better d3 binding
			var sig_labels = matrix.sig_labels.filter(function(x) { return cls[x] == curr_cl; });
			var data = [];
			for (var ind = 0; ind < sig_labels.length; ind++) {
				var sig = sig_labels[ind];
				data.push(matrix.data[matrix.sig_labels.indexOf(sig)]);
			}
			
			if (typeof(sig_labels) == "string") {
				sig_labels = [sig_labels];
			}

			var formatted_data_matrix = sig_labels.map(function(row, i){
				    return data[i].map(function(val, j){
					    return {"val":val, "row":matrix.sig_labels.indexOf(sig_labels[i]), "col":j}
						});
				    });


			var formatted_data_w_row_labels = d3.zip(sig_labels, formatted_data_matrix);

			var summary_data_matrix = computeDataAverages(formatted_data_matrix);
			var summary_data_matrix_w_row_labels = {name:"Signature Cluster " + curr_cl, vals:summary_data_matrix};


			// Sort data if necessary

			var sort_col = matrix.proj_labels.indexOf(global_status.sorted_column);
			if(sort_col > -1){
				sortFun = function(a,b){
					a_precomp = global_data.sigIsPrecomputed[a[0]];
					b_precomp = global_data.sigIsPrecomputed[b[0]];
					if(a_precomp && b_precomp || !a_precomp && !b_precomp){
						return a[1][sort_col].val - b[1][sort_col].val;
					}
					else if (a_precomp) { return -1;}
					else {return 1;}
				};
				formatted_data_w_row_labels.sort(sortFun);
			}

			var colorScale = d3.scale.linear()
				.domain([0,-3,-50])
				.range(["steelblue","white", "lightcoral"])
				.clamp(true);
			
			

			var summary_row = d3.select('#table'+curr_cl).select('thead').select("#summary_row"+curr_cl).selectAll("td")
				.data(["Signature Cluster " + curr_cl].concat(summary_data_matrix));
			summary_row.enter().append('td');
			summary_row.html(function(d) {return "<div class='sigclust' id='sigclust-title_"+curr_cl+ "' onclick=clickSummaryRow(this)>" + d + "</div>";})
				.filter(function(d,i) { return i > 0; })
				.text(function(d, i) {
					if (d < -50) {return '< -50';}
					else if (d > -1) { return d.toFixed(2);}
					else {return d.toPrecision(2);}
				})
				.style('background-color', function(d) {return colorScale(d);})
			summary_row.exit().remove();


			var content_rows = d3.select('#table'+curr_cl).select('tbody').selectAll('tr')
				.data(formatted_data_w_row_labels);
			content_rows.enter().append('tr');
			content_rows.exit().remove();
        
			var content_row = content_rows.selectAll("td")
				.data(function(d, row_num){return [d[0]].concat(d[1]);})

			content_row.enter().append('td');
			content_row.exit().remove();

			content_row
				.filter(function(d,i) { return i > 0;})
				.text(function(d){
					if(d.val < -50) { return "< -50";}
					else if(d.val > -1) { return d.val.toFixed(2);}
					else {return d.val.toPrecision(2);}
						})
			    .style('background-color', function(d){return colorScale(d.val);})
				.on("click", function(d){tableClickFunction(matrix.sig_labels[d.row], matrix.proj_labels[d.col])});

			// Make signature names click-able
			content_row.filter(function(d,i) { return i == 0;})
				.text(function(d){return d;})
				.on("click", function(d){createSigModal(d)});

			
			$('#table'+curr_cl).children('tbody').hide();
            
		}

		// (Re)Create filter signature box
		/*var th = $('.table_div').children('table').children('thead').children('tr').children('th:first-child');
		$(th).append(filterSig);
		filterSig.show();
		filterSig.trigger('input'); */

		$(".sigclust").on("mouseover", function(d) {
			tooltip.showTooltip("Click To Toggle Cluster Display", d);
		})
		.on("mouseout", function(d) {
			tooltip.hideTooltip();
		});
    });
}

function clickSummaryRow(d) {
	var clust = d.id.split("_")[1];
	var summary_row_ind = $("#table"+clust).children('thead').children('#summary_row'+clust).children('td:last');
	if (summary_row_ind.is(":visible")) {
		$("#table"+clust).children('thead').children('#summary_row'+clust).children('td').hide();
		$("#table"+clust).children('thead').children('#summary_row'+clust).children('td:first').show();
		$("#table"+clust).children('tbody').show();
	} else {
		$("#table"+clust).children('thead').children('#summary_row'+clust).children('td').show();
		$("#table"+clust).children('tbody').hide();
	}
}

function computeDataAverages(data) {

	// We want one average per projection 
	averages = Array.apply(null, Array(data[0].length)).map(Number.prototype.valueOf, 0);
	for (i = 0; i < data.length; i++) {
		for (j = 0; j < data[i].length; j++) {
			averages[j] += data[i][j].val;
		}
	}
	for (i = 0; i < averages.length; i++) {
		averages[i] /= data.length;
	}
	return averages;
}

function createSigModal(sig_key){

    return api.signature.info(sig_key).then(function(sig_info){

        var sig_data = [];
        for(gene in sig_info['sigDict'])
        {
            sig_data.push({'Gene': gene, 'Sign': sig_info['sigDict'][gene]});
        }
        var sigModal = $('#signatureModal');
        sigModal.find('h4').text(sig_key);
        var tableRows = d3.select('#signatureModal').select('tbody').selectAll('tr')
                .data(sig_data);
        tableRows.enter().append('tr');
        tableRows.exit().remove();

        var tableCells = tableRows.selectAll('td').data(function(d){return [d.Gene, d.Sign];});
        tableCells.enter().append('td');
        tableCells.text(function(d, i){
            if(i == 0){return d;}
            else{
                if(d == 1)  {return "+";}
                if(d == -1) {return "-";}
                if(d == 0)  {return "Unsigned";}
                return "Unknown";
                }
            });

        tableCells.exit().remove();

        sigModal.modal();
    });
}

function createGeneModal()
{
    return api.filterGroup.genes(global_status.filter_group)
        .then(function(genes){

            //Calculate max width
            var width_and_index = genes.map(function(e,i){return [e.length, i]});
            width_and_index.sort(function(a,b){return Math.sign(b[0] - a[0]);});
            var top10 = width_and_index.slice(0,10).map(function(e,i){return genes[e[1]];});
            var widths = [];
            for(var i = 0; i < top10.length; i++)
            {
                var div = document.createElement("div");
                $(div).text(top10[i]).css("position","absolute").css("left", "-9999px");
                $('body').append(div);
                widths.push($(div).width());
            }
            
            var maxWidth = d3.max(widths);
            
            var geneDivs = d3.select('#geneModal').select('.modal-body').selectAll('div')
                .data(genes.sort());
                
            geneDivs.enter().append('div');
            geneDivs.exit().remove();
            
            geneDivs
                .text(function(d){return d;})
                .style("width", maxWidth + "px");
            
            $('#geneModal').modal();
        });
}


function changeTableView()
{
	var precomp = document.getElementById("precomputed_button").innerHTML;
	if (precomp == "Precomputed") {
		document.getElementById("precomputed_button").innerHTML = "Computed";
	} else {
		document.getElementById("precomputed_button").innerHTML = "Precomputed";
	}
	global_status.precomputed = !(global_status.precomputed);
	return createTableFromData(); 
}

function exportSigProj() {
	
    var sig_key = global_status.plotted_signature;
    var proj_key = global_status.plotted_projection;
    var filter_group = global_status.filter_group;

    if(sig_key.length == 0 && proj_key.length == 0){
        $('#plot_title_div').children().eq(0).text("");
        $('#plot_title_div').children().eq(1).text("");
        global_scatter.setData([], false);
        return $().promise()
    }

    var proj_promise = api.projection.coordinates(filter_group, proj_key);
	
	var sig_promise;
    if(global_status.scatterColorOption == "value" || 
        global_data.sigIsPrecomputed[sig_key])
        {sig_promise = api.signature.scores(sig_key)}

    if(global_status.scatterColorOption == "rank") 
        {sig_promise = api.signature.ranks(sig_key)}


    return $.when(proj_promise, sig_promise) // Runs when both are completed
        .then(function(projection, signature, sig_info){
            
            $('#plot_title_div').children().eq(0).text(proj_key);
            $('#plot_title_div').children().eq(1).text(sig_key);

            var points = [];
            for(sample_label in signature){
                var x = projection[sample_label][0]
                var y = projection[sample_label][1]
                var sig_score = signature[sample_label]
                points.push([x, y, sig_score, sample_label]);
            }
			
			var lineArray = [];
			points.forEach(function(infoArray, index) {
				var line = infoArray.join(",");
				lineArray.push(index == 0 ? "data:text/csv;charset=utf-8," + line : line);
			});
			var csvContent = lineArray.join("\n");

			var encodedURI = encodeURI(csvContent);
			var downloadLink = document.createElement("a");
			downloadLink.setAttribute("href", encodedURI);
			downloadLink.setAttribute("download", proj_key + ".csv");
			downloadLink.onclick = destroyClickedElement;
			downloadLink.style.display = "none";
			document.body.appendChild(downloadLink);

			downloadLink.click();

        });

}

function destroyClickedElement(event) {
	document.body.removeChild(event.target);
}