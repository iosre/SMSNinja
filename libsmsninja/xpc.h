#ifdef __cplusplus
extern "C"
{
#endif
    
#define XPC_EXPORT extern __attribute__((visibility("default")))
#define XPC_TYPE(type) const struct _xpc_type_s type
    typedef void * xpc_object_t;
#define XPC_DECL(name) typedef struct _##name##_s * name##_t
    
#define XPC_ERROR_KEY_DESCRIPTION _xpc_error_key_description
    XPC_EXPORT
    const char *_xpc_error_key_description;
    
#define XPC_TYPE_CONNECTION (&_xpc_type_connection)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_connection);
    XPC_DECL(xpc_connection);
    
#define XPC_TYPE_ENDPOINT (&_xpc_type_endpoint)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_endpoint);
    XPC_DECL(xpc_endpoint);
    
#define XPC_TYPE_NULL (&_xpc_type_null)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_null);
    
#define XPC_TYPE_BOOL (&_xpc_type_bool)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_bool);
    
#define XPC_BOOL_TRUE XPC_GLOBAL_OBJECT(_xpc_bool_true)
    XPC_EXPORT
    const struct _xpc_bool_s _xpc_bool_true;
    
#define XPC_BOOL_FALSE XPC_GLOBAL_OBJECT(_xpc_bool_false)
    XPC_EXPORT
    const struct _xpc_bool_s _xpc_bool_false;
    
#define XPC_TYPE_INT64 (&_xpc_type_int64)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_int64);
    
#define XPC_TYPE_UINT64 (&_xpc_type_uint64)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_uint64);
    
#define XPC_TYPE_DOUBLE (&_xpc_type_double)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_double);
    
#define XPC_TYPE_DATE (&_xpc_type_date)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_date);
    
#define XPC_TYPE_DATA (&_xpc_type_data)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_data);
    
#define XPC_TYPE_STRING (&_xpc_type_string)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_string);
    
#define XPC_TYPE_UUID (&_xpc_type_uuid)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_uuid);
    
#define XPC_TYPE_FD (&_xpc_type_fd)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_fd);
    
#define XPC_TYPE_SHMEM (&_xpc_type_shmem)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_shmem);
    
#define XPC_TYPE_ARRAY (&_xpc_type_array)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_array);
    
#define XPC_TYPE_DICTIONARY (&_xpc_type_dictionary)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_dictionary);
    
#define XPC_TYPE_ERROR (&_xpc_type_error)
    XPC_EXPORT
    XPC_TYPE(_xpc_type_error);
    
    typedef void (^xpc_handler_t)(xpc_object_t object);
    typedef const struct _xpc_type_s * xpc_type_t;
    typedef void (*xpc_connection_handler_t)(xpc_connection_t connection);
    
    xpc_connection_t xpc_connection_create(const char *name, dispatch_queue_t targetq);
    xpc_connection_t xpc_connection_create_mach_service(const char *name, dispatch_queue_t targetq, uint64_t flags);
    xpc_object_t xpc_dictionary_create(const char * const *keys, const xpc_object_t *values, size_t count);
    void xpc_dictionary_set_int64(xpc_object_t xdict, const char *key, int64_t value);
    void xpc_dictionary_set_data(xpc_object_t xdict, const char *key, const void *bytes, size_t length);
    void xpc_dictionary_set_string(xpc_object_t xdict, const char *key, const char *string);
    void xpc_dictionary_set_bool(xpc_object_t xdict, const char *key, bool value);
    const char* xpc_dictionary_get_string(xpc_object_t xdict, const char *key);
    void xpc_release(xpc_object_t object);
    void xpc_connection_send_message(xpc_connection_t connection, xpc_object_t message);
    xpc_object_t xpc_connection_send_message_with_reply_sync(xpc_connection_t connection, xpc_object_t message);
    void xpc_connection_set_event_handler(xpc_connection_t connection, xpc_handler_t handler);
    void xpc_connection_resume(xpc_connection_t connection);
    xpc_type_t xpc_get_type(xpc_object_t object);
    xpc_object_t xpc_dictionary_get_value(xpc_object_t xdict, const char *key);
    void xpc_connection_send_message_with_reply(xpc_connection_t connection, xpc_object_t message, dispatch_queue_t replyq, xpc_handler_t handler);
    xpc_object_t xpc_dictionary_create_reply(xpc_object_t original);
#ifdef __cplusplus
}
#endif
