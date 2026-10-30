/**
 * One-request-lifetime notifications (toasts) and form state (values + errors)
 * carried across a redirect (Post/Redirect/Get). Stored in the session.
 */
component output="false" {

    /** @type success | danger | warning | info */
    public void function add(required string type, required string message) {
        if (!structKeyExists(session, "flash")) {
            session.flash = [];
        }
        arrayAppend(session.flash, {type = arguments.type, message = arguments.message});
    }

    /** Returns pending messages and clears them. */
    public array function consume() {
        if (!structKeyExists(session, "flash")) {
            return [];
        }
        var messages = session.flash;
        session.flash = [];
        return messages;
    }

    public void function stashForm(required numeric id, required struct values, required struct errors) {
        session.formState = {id = arguments.id, values = arguments.values, errors = arguments.errors};
    }

    /** Returns the stashed form state for this employee id (0 = new) and clears it; empty struct otherwise. */
    public struct function popForm(required numeric id) {
        if (structKeyExists(session, "formState")) {
            var state = session.formState;
            structDelete(session, "formState");
            if (state.id == arguments.id) {
                return state;
            }
        }
        return {};
    }

}
