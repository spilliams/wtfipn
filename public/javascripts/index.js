$(document).ready(function(){
    $.ajax("/reason", {
        complete: function(xhr, status) {
            $("#reason").html(xhr.responseText);
        }
    });
});