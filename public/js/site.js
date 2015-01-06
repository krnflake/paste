// Handler for .ready() called.
$(function() {
    $('[data-toggle="tooltip"]').tooltip();

    var changed = false;
    var modelist = ace.require('ace/ext/modelist');
    var editor = ace.edit("editor");
    editor.setTheme("ace/theme/crimson_editor");
    mode = modelist.getModeForPath(location.pathname).mode;
    editor.getSession().setMode(mode);
    editor.setShowPrintMargin(false);

    editor.getSession().on('change', function() {
        changed = true;
    });

    $("#button-save").click(function(e) {
        e.preventDefault();
        var code = editor.getSession().getValue();
        if (!code || 0 === code.length || !changed) return;
        $.ajax({
            type: "POST",
            url: "/p",
            data: { code: code }
        })
        .success(function(data) {
            window.location.href = data.key;
        });
    });

    $("#button-upload").click(function(e) {
        e.preventDefault();
        $("input[type=file]").click();
    });

    $('input[type=file]').change(function () {
        upload($("input[type=file]")[0].files[0]);
    });

    document.ondragover = function(e) {
        e.preventDefault();
        e.stopPropagation();
        $('#dropModal').modal('show');
    }

    document.ondragleave = function(e) {
        e.preventDefault();
        e.stopPropagation();
        $('#dropModal').modal('hide');
    }

    document.ondrop = function(e) {
        e.preventDefault();
        upload(e.dataTransfer.files[0]);
    };

    function upload(file) {
        var formData = new FormData();
        // only upload the first file
        formData.append('blob', file);

        // now post a new XHR request
        var xhr = new XMLHttpRequest();
        xhr.open('POST', '/p');
        xhr.onload = function () {
            if (xhr.status === 200) {
                window.location = JSON.parse(xhr.response).raw;
            }
        };

        xhr.send(formData);
    }
});
