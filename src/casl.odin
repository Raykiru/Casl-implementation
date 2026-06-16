#+vet explicit-allocators
package casl

import "core:fmt"
import tknz "core:odin/tokenizer"
import "core:os"


get_graph_from_command_args :: proc(
	allocator := context.allocator,
) -> (
	graph: map[string]^Graph_node,
	err: union {
		Parse_error,
		os.Error,
	},
) {
	file := os.args[1] if len(os.args) > 1 else ""
	if file == "" {fmt.eprint("No file provided"); os.exit(1)}

	file_contents := os.read_entire_file_from_path(file, allocator) or_return

	graph, err = get_graph_from_src(cast(string)file_contents, allocator)

	return
}

get_graph_from_src :: proc(
	src: string,
	allocator := context.allocator,
) -> (
	graph: map[string]^Graph_node,
	err: Parse_error,
) {

	tk: tknz.Tokenizer
	tknz.init(&tk, src, "")


	tknz.custom_keyword_tokens = {"true", "false"}

	global_list := make([dynamic]string, allocator)
	key_loop: for {
		debug_print("Parsing first level of key_value pairs")
		key := parse_key_val(&tk, &graph, allocator = allocator) or_return

		if key == "" {break}

		append(&global_list, key)

	}

	graph[""] = new_clone(Graph_node{data = cast(List)global_list[:]}, allocator)
	return
}
