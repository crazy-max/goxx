// Package jq implements C bindings to libjq 1.6-rc2+.
//
// Because libjq uses callbacks for error handling, this library should not
// be considered thread-safe.
package main

/*
#cgo LDFLAGS: -L . -ljq -lonig

#include <stdlib.h>
#include <jq.h>

void gojq_set_error_cb(jq_state*, unsigned long long);
void gojq_reset_error_cb(jq_state*);
*/
import "C"

import (
	"errors"
	"fmt"
	"math/rand"
	"reflect"
	"unsafe"
)

//export errorCallback
func errorCallback(id C.ulonglong, failedJV C.jv) {
	err := errorFromJv(failedJV)
	if err == nil {
		panic("error callback executed for nonexistant error")
	}
	callbackID := uint64(id)
	callbackErrors[callbackID] = append(callbackErrors[callbackID], err)
}

func jvToGoValue(jv C.jv) interface{} {
	kind := C.jv_get_kind(jv)
	switch kind {
	case C.JV_KIND_NULL:
		return nil
	case C.JV_KIND_FALSE:
		return false
	case C.JV_KIND_TRUE:
		return true
	case C.JV_KIND_NUMBER:
		val := C.jv_number_value(jv)
		if C.jv_is_integer(jv) == 1 {
			return int(val)
		}
		return float64(val)
	case C.JV_KIND_STRING:
		return C.GoString(C.jv_string_value(jv))
	case C.JV_KIND_ARRAY:
		arrayLen := int(C.jv_array_length(C.jv_copy(jv)))
		array := make([]interface{}, arrayLen)
		for i := 0; i < arrayLen; i++ {
			v := C.jv_array_get(C.jv_copy(jv), C.int(i))
			array[i] = jvToGoValue(v)
			C.jv_free(v)
		}
		return array
	case C.JV_KIND_OBJECT:
		obj := make(map[string]interface{})
		for iter := C.jv_object_iter(jv); C.jv_object_iter_valid(jv, iter) == 1; iter = C.jv_object_iter_next(jv, iter) {
			jvKey := C.jv_object_iter_key(jv, iter)
			jvValue := C.jv_object_iter_value(jv, iter)
			// This is safe because jv_object_iter_key asserts the jv is a string.
			key := C.GoString(C.jv_string_value(jvKey))

			obj[key] = jvToGoValue(jvValue)

			C.jv_free(jvKey)
			C.jv_free(jvValue)
		}
		return obj
	}
	panic("unreachable")
}

func dumpJvToGoStr(jv C.jv) string {
	// jv_dump_string frees the provided jv, so we copy it.
	dumpedjv := C.jv_dump_string(C.jv_copy(jv), C.int(0))
	defer C.jv_free(dumpedjv)

	// Strings from jv_string_value are cleaned up when the jv is freed.
	return C.GoString(C.jv_string_value(dumpedjv))
}

func jvInterface(i interface{}) C.jv {
	if i == nil {
		return C.jv_null()
	}

	// Handle simple types.
	switch val := i.(type) {
	case int, int8, int16, int32, int64,
		uint, uint8, uint16, uint32, uint64,
		float32, float64:
		return jvNumber(val)
	case string:
		return jvString(val)
	case []byte:
		return jvString(string(val))
	case bool:
		if val {
			return C.jv_true()
		}
		return C.jv_false()
	}

	// Handle complex types.
	val := reflect.ValueOf(i)
	switch val.Kind() {
	case reflect.Array, reflect.Slice:
		return jvArray(val)
	case reflect.Map:
		return jvMap(val)
	}

	panic("unknown type attempted to be cast to jv")
}

func jvMap(val reflect.Value) C.jv {
	jvObj := C.jv_object()
	for _, key := range val.MapKeys() {
		// These allocations are freed when the whole object is freed.
		keyJv := jvString(key.String())
		valueJv := jvInterface(val.MapIndex(key).Interface())

		C.jv_object_set(jvObj, keyJv, valueJv)
	}
	return jvObj
}

func jvArray(val reflect.Value) C.jv {
	len := val.Len()
	jvArray := C.jv_array_sized(C.int(len))

	for i := 0; i < len; i++ {
		// These allocations are freed when the whole array is freed.
		jvArray = C.jv_array_set(jvArray, C.int(i), jvInterface(val.Index(i).Interface()))
	}

	return jvArray
}

func jvString(i interface{}) C.jv {
	str := i.(string)
	cstr := C.CString(str)
	defer C.free(unsafe.Pointer(cstr))
	return C.jv_string_sized(cstr, C.int(len(str)))
}

func jvNumber(i interface{}) C.jv {
	val := reflect.ValueOf(i)
	switch val.Kind() {
	case reflect.Float32, reflect.Float64:
		return C.jv_number(C.double(val.Float()))
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		return C.jv_number(C.double(float64(val.Int())))
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		return C.jv_number(C.double(float64(val.Uint())))
	}

	panic("unknown type for go number")
}

var (
	// libjq uses callbacks for error handling.
	// This map stores errors under a key for a particular call.
	// See https://github.com/golang/go/wiki/cgo#function-variables
	callbackErrors = make(map[uint64][]error)
)

func errorFromJv(jv C.jv) error {
	jv = C.jq_format_error(jv)
	defer C.jv_free(jv)

	if C.jv_get_kind(jv) == C.JV_KIND_NULL {
		return nil
	}
	return errors.New(C.GoString(C.jv_string_value(jv)))
}

// Exec compiles a JQ program with the provided args and executes it with the
// provided input.
//
// The args and input parameters are expected to be JSON bytes.
// If the args parameter is not null, an array, or an object, then ErrWrongType
// is returned.
func Exec(program string, args, input []byte, raw bool) ([]string, error) {
	state, err := C.jq_init()
	if err != nil {
		return nil, err
	} else if state == nil {
		panic("failed to initialize jq state")
	}
	defer C.jq_teardown(&state)

	argsPtr := C.CString(string(args))
	defer C.free(unsafe.Pointer(argsPtr))
	argsJv := C.jv_parse(argsPtr)
	if C.jv_is_valid(argsJv) == 0 {
		return nil, errorFromJv(argsJv)
	}
	defer C.jv_free(argsJv)

	inputPtr := C.CString(string(input))
	defer C.free(unsafe.Pointer(inputPtr))
	inputJv := C.jv_parse(inputPtr)
	if C.jv_is_valid(inputJv) == 0 {
		return nil, errorFromJv(inputJv)
	}
	defer C.jv_free(inputJv)

	return executeProgram(state, program, argsJv, inputJv, raw)
}

// executeProgram compiles and executes a jq program with the provided
// arguments and input.
func executeProgram(state *C.struct_jq_state, program string, args, input C.jv, raw bool) ([]string, error) {
	errs := compile(state, program, args)
	if len(errs) != 0 {
		err := errs[0]
		for i := 1; i < len(errs); i++ {
			err = errors.New(err.Error() + "; " + errs[i].Error())
		}
		return nil, err
	}

	return execute(state, input, raw)
}

// execute performs an execution of the previous compiled program.
// compile() must be called before this function.
func execute(state *C.struct_jq_state, input C.jv, raw bool) ([]string, error) {
	// I can't figure out where, but it seems like jq_start frees input.
	C.jq_start(state, C.jv_copy(input), C.int(0))

	results := make([]string, 0)

	var result C.jv
	for result = C.jq_next(state); C.jv_is_valid(result) == 1; result = C.jq_next(state) {
		var str string
		if raw && C.jv_get_kind(result) == C.JV_KIND_STRING {
			str = C.GoString(C.jv_string_value(result))
		} else {
			str = dumpJvToGoStr(result)
		}
		results = append(results, str)
		C.jv_free(result)
	}

	return results, invalidError(result)
}

func invalidError(jv C.jv) error {
	// jv_invalid_get_msg frees jv.
	msg := C.jv_invalid_get_msg(jv)
	defer C.jv_free(msg)

	switch C.jv_get_kind(msg) {
	case C.JV_KIND_NULL:
		return nil
	case C.JV_KIND_STRING:
		return errors.New(C.GoString(C.jv_string_value(msg)))
	default:
		return errors.New(dumpJvToGoStr(msg))
	}
}

// collectErrors wraps a closure that calls jv functions that perform error
// handling via callback.
func collectErrors(state *C.struct_jq_state, fn func()) []error {
	callbackID := rand.Uint64()
	C.gojq_set_error_cb(state, C.ulonglong(callbackID))
	defer C.gojq_reset_error_cb(state)

	callbackErrors[callbackID] = nil
	defer delete(callbackErrors, callbackID)

	fn()

	return callbackErrors[callbackID]
}

// ErrWrongType is returned from functions when an assertion about the type of
// a value fails.
type ErrWrongType struct {
	message string
}

func (e *ErrWrongType) Error() string {
	return e.message
}

// compile prepares a jq program for execution.
// The provided args must be KindArray or KindObject.
func compile(state *C.struct_jq_state, program string, args C.jv) []error {
	// This check is done in libjq, but it's faster to check here and bail early.
	kind := C.jv_get_kind(args)
	if !(kind == C.JV_KIND_ARRAY || kind == C.JV_KIND_OBJECT) {
		return []error{&ErrWrongType{fmt.Sprintf("args was not the required type, got %s, expected: %s or %s", jvKindName(kind), jvKindName(C.JV_KIND_OBJECT), jvKindName(C.JV_KIND_ARRAY))}}
	}

	return collectErrors(state, func() {
		cprog := C.CString(program)
		defer C.free(unsafe.Pointer(cprog))

		// jq_compile_args frees the args JV, so we provide a copy for sanity.
		C.jq_compile_args(state, cprog, C.jv_copy(args))
	})
}

func jvKindName(kind C.jv_kind) string {
	return C.GoString(C.jv_kind_name(kind))
}
