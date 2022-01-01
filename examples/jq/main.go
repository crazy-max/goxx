package main

import (
	"encoding/json"
	"fmt"
)

func main() {
	input := []byte(`[{"foo":true},{"bar":false},{"fizz":"buzz"},{"cats":"dogs"}]`)

	args, err := marshalJqArgs(input, programArguments{})
	if err != nil {
		panic(err)
	}

	res, err := Exec(".", args, input, true)
	if err != nil {
		panic(err)
	}

	fmt.Println(res)
}

// programArguments contains the arguments to a JQ program
type programArguments struct {
	Args       []string
	Jsonargs   []interface{}
	Kwargs     map[string]string
	Jsonkwargs map[string]interface{}
}

func marshalJqArgs(jsonBytes []byte, jqArgs programArguments) ([]byte, error) {
	var positionalArgsArray []interface{}
	programArgs := make(map[string]interface{})
	namedArgs := make(map[string]interface{})

	for _, value := range jqArgs.Args {
		positionalArgsArray = append(positionalArgsArray, value)
	}
	positionalArgsArray = append(positionalArgsArray, jqArgs.Jsonargs...)
	for key, value := range jqArgs.Kwargs {
		programArgs[key] = value
		namedArgs[key] = value
	}
	for key, value := range jqArgs.Jsonkwargs {
		programArgs[key] = value
		namedArgs[key] = value
	}

	programArgs["ARGS"] = map[string]interface{}{
		"positional": positionalArgsArray,
		"named":      namedArgs,
	}

	return json.Marshal(programArgs)
}
