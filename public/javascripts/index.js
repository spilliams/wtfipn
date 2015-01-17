reload = function() {
    $.ajax("/reason", {
        complete: function(xhr, status) {
            $("#reason").html(xhr.responseText);
            $("#reason a").click(function(){reload()});
        }
    });
};

$(document).ready(function(){
    reload();
});
