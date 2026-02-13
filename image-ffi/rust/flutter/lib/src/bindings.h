#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct BufferCap {
  uint8_t *ptr;
  uintptr_t len;
  uintptr_t cap;
} BufferCap;

typedef struct Buffer {
  uint8_t *ptr;
  uintptr_t len;
} Buffer;

bool init_http_client(void);

/**
 * Poll for completed requests. Returns number of completions processed.
 * This MUST be called from a Dart isolate thread.
 *
 * # Safety
 * - callback must be a valid function pointer
 * - max_completions should be reasonable (e.g., 1-100)
 */
uintptr_t poll_completions(void (*callback)(uint64_t token, const uint8_t *ptr, uintptr_t len),
                           uintptr_t max_completions);

/**
 * Check if there are any pending completions without processing them.
 * Useful for conditional polling.
 */
bool has_pending_completions(void);

/**
 * Get the approximate number of pending completions.
 */
uintptr_t pending_completions_count(void);

struct BufferCap allocate_request_buffer(uintptr_t capacity);

void set_buffer_len(uint8_t *ptr, uintptr_t len, uintptr_t cap);

bool execute_request_binary_async(uint8_t *ptr,
                                  uintptr_t len,
                                  uintptr_t cap,
                                  uint64_t completion_token);

bool execute_requests_batch_binary_async(uint8_t *ptr,
                                         uintptr_t len,
                                         uintptr_t cap,
                                         uint64_t completion_token);

struct Buffer execute_request_binary(const uint8_t *request_ptr, uintptr_t request_len);

struct Buffer execute_requests_batch_binary(const uint8_t *requests_ptr, uintptr_t requests_len);

void free_buffer_with_capacity(uint8_t *ptr, uintptr_t len, uintptr_t cap);

void free_buffer(uint8_t *ptr, uintptr_t len);

void shutdown_http_client(void);
