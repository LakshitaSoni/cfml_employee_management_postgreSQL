<cfprocessingdirective pageEncoding="utf-8">
<cfparam name="deleteReturnQuery" default="">
<!--- Shared confirmation dialog. JS (app.js) fills in the employee id/name from the clicked button's data-* attributes. --->
<cfoutput>
<div class="modal fade" id="deleteModal" tabindex="-1" aria-labelledby="deleteModalTitle" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <form class="modal-content" method="post" action="#root#employees/delete.cfm" data-loading>
            #csrf.field()#
            <input type="hidden" name="id" id="deleteId" value="">
            <input type="hidden" name="returnQuery" value="#ha(deleteReturnQuery)#">
            <div class="modal-body text-center p-4 pb-3">
                <div class="modal-icon modal-icon-danger"><i class="bi bi-trash3-fill"></i></div>
                <h2 class="h5 mb-2" id="deleteModalTitle">Delete this employee?</h2>
                <p class="text-secondary mb-0">
                    You are about to permanently delete <strong id="deleteName">this employee</strong>.
                    This action cannot be undone.
                </p>
            </div>
            <div class="modal-footer border-0 justify-content-center pb-4 pt-0">
                <button type="button" class="btn btn-light px-4" data-bs-dismiss="modal">Cancel</button>
                <button type="submit" class="btn btn-danger px-4"><span class="btn-label"><i class="bi bi-trash3 me-1"></i>Yes, delete</span></button>
            </div>
        </form>
    </div>
</div>
</cfoutput>
