/* People Hub - progressive enhancement. The app works without JS (server-side validation,
   plain form posts); this layer adds validation feedback, loading states and dialogs. */
(function () {
    "use strict";

    var spinnerHtml = '<span class="spinner-border" role="status" aria-hidden="true"></span>';

    // ---- Toasts: show every flash message rendered by the server ----------------
    document.querySelectorAll("#toastRegion .toast").forEach(function (el) {
        bootstrap.Toast.getOrCreateInstance(el).show();
    });

    // ---- Delete confirmation modal: fill id + name from the clicked button ------
    var deleteModal = document.getElementById("deleteModal");
    if (deleteModal) {
        deleteModal.addEventListener("show.bs.modal", function (event) {
            var button = event.relatedTarget;
            if (!button) { return; }
            document.getElementById("deleteId").value = button.getAttribute("data-employee-id") || "";
            document.getElementById("deleteName").textContent = button.getAttribute("data-employee-name") || "this employee";
        });
        deleteModal.addEventListener("hidden.bs.modal", function () {
            resetLoading(deleteModal.querySelector("form"));
        });
    }

    // ---- Loading state on submit buttons ----------------------------------------
    function setLoading(form) {
        var btn = form.querySelector('button[type="submit"]');
        if (!btn || btn.classList.contains("is-loading")) { return; }
        btn.classList.add("is-loading");
        btn.setAttribute("aria-busy", "true");
        var label = btn.querySelector(".btn-label");
        if (label) { label.insertAdjacentHTML("afterbegin", spinnerHtml); }
        // Disable on the next tick so the submit (and its button value) still goes through
        setTimeout(function () { btn.disabled = true; }, 0);
    }
    function resetLoading(form) {
        if (!form) { return; }
        var btn = form.querySelector('button[type="submit"]');
        if (!btn) { return; }
        btn.disabled = false;
        btn.classList.remove("is-loading");
        btn.removeAttribute("aria-busy");
        var spinner = btn.querySelector(".spinner-border");
        if (spinner) { spinner.remove(); }
    }
    // Back/forward cache: never leave a button stuck in the loading state
    window.addEventListener("pageshow", function () {
        document.querySelectorAll("form[data-loading]").forEach(resetLoading);
        var loader = document.getElementById("pageLoader");
        if (loader) { loader.hidden = true; }
        var tl = document.querySelector(".table-loading");
        if (tl) { tl.hidden = true; }
    });

    // ---- Client-side validation (server re-validates everything) ----------------
    document.querySelectorAll("form.needs-validation").forEach(function (form) {
        form.addEventListener("submit", function (event) {
            if (!form.checkValidity()) {
                event.preventDefault();
                event.stopPropagation();
                form.classList.add("was-validated");
                form.querySelectorAll(":invalid").forEach(function (field) { showMessage(field); });
                var first = form.querySelector(":invalid");
                if (first) { first.focus(); }
                return;
            }
            if (form.hasAttribute("data-loading")) { setLoading(form); }
        });
        form.querySelectorAll("input, select").forEach(function (field) {
            field.addEventListener("input", function () {
                field.classList.remove("is-invalid");            // clear a server-side error once edited
                var fb = feedbackFor(field);
                if (fb && fb.hasAttribute("data-server")) { fb.removeAttribute("data-server"); }
                if (form.classList.contains("was-validated")) { showMessage(field); }
            });
        });
    });
    document.querySelectorAll("form[data-loading]:not(.needs-validation)").forEach(function (form) {
        form.addEventListener("submit", function () { setLoading(form); });
    });

    function feedbackFor(field) {
        var holder = field.closest(".input-group") || field.parentElement;
        return holder ? holder.querySelector(".invalid-feedback") : null;
    }
    function showMessage(field) {
        var fb = feedbackFor(field);
        if (fb && !fb.hasAttribute("data-server")) { fb.textContent = field.validationMessage; }
    }

    // ---- Live profile preview on the employee form --------------------------------
    var previewForm = document.querySelector("[data-preview-form]");
    if (previewForm) {
        var nameEl = previewForm.querySelector("[data-preview-name]");
        var titleEl = previewForm.querySelector("[data-preview-title]");
        var deptEl = previewForm.querySelector("[data-preview-dept]");
        var initialsOf = function (name) {
            var words = name.trim().split(/\s+/).filter(Boolean);
            if (!words.length) { return "?"; }
            var s = words[0].charAt(0);
            if (words.length > 1) { s += words[words.length - 1].charAt(0); }
            return s.toUpperCase();
        };
        var sync = function () {
            document.getElementById("previewAvatar").textContent = initialsOf(nameEl.value);
            document.getElementById("previewName").textContent = nameEl.value.trim() || "New employee";
            document.getElementById("previewTitle").textContent = titleEl.value.trim() || "Job title";
            document.getElementById("previewDept").textContent = deptEl.value.trim() || "Department";
        };
        [nameEl, titleEl, deptEl].forEach(function (el) { el.addEventListener("input", sync); });
    }

    // ---- Directory filters: auto-submit with a loading overlay ---------------------
    var filterForm = document.querySelector("form[data-autosubmit]");
    if (filterForm) {
        var timer;
        var submitFilters = function () {
            var overlay = document.querySelector(".table-loading");
            if (overlay) { overlay.hidden = false; }
            filterForm.submit();
        };
        filterForm.querySelectorAll("select").forEach(function (sel) {
            sel.addEventListener("change", submitFilters);
        });
        filterForm.querySelectorAll("[data-debounce]").forEach(function (input) {
            input.addEventListener("input", function () {
                clearTimeout(timer);
                timer = setTimeout(submitFilters, 600);
            });
        });
        filterForm.addEventListener("submit", function () {
            var overlay = document.querySelector(".table-loading");
            if (overlay) { overlay.hidden = false; }
        });
        // Keep the caret at the end of the search box after a reload triggered by typing
        var search = document.getElementById("fSearch");
        if (search && search.value && document.referrer.indexOf(location.pathname) !== -1) {
            search.focus();
            search.setSelectionRange(search.value.length, search.value.length);
        }
    }

    // ---- Sort / pagination links show the loading overlay too ----------------------
    document.querySelectorAll(".sort-link, .pagination .page-link").forEach(function (link) {
        link.addEventListener("click", function () {
            var overlay = document.querySelector(".table-loading");
            if (overlay) { overlay.hidden = false; }
        });
    });
})();
