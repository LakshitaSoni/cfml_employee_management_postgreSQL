/**
 * Synchronizer-token CSRF protection. One random token per session, embedded
 * in every state-changing form and compared in constant time on POST.
 */
component output="false" {

    public string function generate() {
        return lcase(hash(generateSecretKey("AES", 256) & createUUID(), "SHA-256"));
    }

    public string function token() {
        if (!structKeyExists(session, "csrfToken")) {
            session.csrfToken = generate();
        }
        return session.csrfToken;
    }

    /** <input type="hidden"> carrying the token (field name: csrf_token) */
    public string function field() {
        return '<input type="hidden" name="csrf_token" value="' & encodeForHTMLAttribute(token()) & '">';
    }

    public boolean function verify(required string submitted) {
        if (!structKeyExists(session, "csrfToken") || !len(arguments.submitted)) {
            return false;
        }
        return createObject("java", "java.security.MessageDigest").isEqual(
            session.csrfToken.getBytes("UTF-8"),
            arguments.submitted.getBytes("UTF-8")
        );
    }

}
