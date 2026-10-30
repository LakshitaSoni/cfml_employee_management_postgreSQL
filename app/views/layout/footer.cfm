<cfprocessingdirective pageEncoding="utf-8">
<cfset toastIcons = {success = "bi-check-circle-fill", danger = "bi-exclamation-octagon-fill", warning = "bi-exclamation-triangle-fill", info = "bi-info-circle-fill"}>
<cfoutput>
        </main>

        <footer class="app-footer">
            <span>&copy; #year(now())# People Hub &middot; Employee Management System</span>
        </footer>
    </div>
</div>

<!--- Notifications (flash messages from the previous request) --->
<div class="toast-container position-fixed top-0 end-0 p-3" id="toastRegion" aria-live="polite" aria-atomic="true">
    <cfloop array="#flash.consume()#" index="note">
        <cfset nType = structKeyExists(toastIcons, note.type) ? note.type : "info">
        <div class="toast app-toast toast-#nType#" role="#nType eq 'danger' ? 'alert' : 'status'#" data-bs-delay="#nType eq 'danger' ? 9000 : 5000#">
            <div class="d-flex align-items-start gap-2 p-3">
                <i class="bi #toastIcons[nType]# toast-icon"></i>
                <div class="flex-grow-1">#h(note.message)#</div>
                <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>
            </div>
        </div>
    </cfloop>
</div>

<div class="page-loader" id="pageLoader" hidden><div class="spinner-border text-primary" role="status"><span class="visually-hidden">Loading&hellip;</span></div></div>

<script src="#root#assets/vendor/bootstrap/bootstrap.bundle.min.js"></script>
<script src="#root#assets/js/app.js?v=1"></script>
</body>
</html>
</cfoutput>
