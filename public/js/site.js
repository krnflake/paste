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
            window.location.href = data.link;
        });
    });

    $("#button-upload").click(function(e) {
        e.preventDefault();
        $("input[type=file]").click();
    });

    $('input[type=file]').change(function () {
        upload($("input[type=file]")[0].files[0]);
    });

    $("#sidebar").on("dragover", function(e) {
        e.preventDefault();
        e.stopPropagation();
        $('#dropMsg').show();
    });

    $("#sidebar").on("dragleave", function(e) {
        e.preventDefault();
        e.stopPropagation();
        $('#dropMsg').hide();
    });

    $("#sidebar").on("drop", function(e) {
        e.preventDefault();
        e.stopPropagation();
        upload(e.dataTransfer.files[0]);
    });

    function upload(file) {
        var formData = new FormData();
        // only upload the first file
        formData.append('blob', file);

        // now post a new XHR request
        var xhr = new XMLHttpRequest();

        NProgress.start();
        xhr.open('POST', '/p');
        xhr.onprogress = function (e) {
            if (e.lengthComputable) {
                NProgress.set(e.loaded / e.total);
            }
        };
        xhr.onload = function () {
            NProgress.done();
            if (xhr.status === 200) {
                window.location = JSON.parse(xhr.response).raw;
            }
        };
        xhr.send(formData);
    };
});
