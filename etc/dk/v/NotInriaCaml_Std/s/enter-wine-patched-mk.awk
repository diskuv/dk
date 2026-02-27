{ 
    gsub(/@WINEHOME@/, WINEHOME);
    gsub(/@GNUTLS_LIBDIR@/, GNUTLS_LIBDIR);
    gsub(/@INOTIFY_LIBDIR@/, INOTIFY_LIBDIR);
    gsub(/@KRB5_LIBDIR@/, KRB5_LIBDIR);
    print $0 > OUTPUT_FILE;
}