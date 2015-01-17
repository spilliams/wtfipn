reload = function() {
    $.ajax("/reason", {
        complete: function(xhr, status) {
            $("#reason").html(xhr.responseText);
        }
    });
};

$(document).ready(function(){
    reload();
});
