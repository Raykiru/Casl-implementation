
package main

import "core:fmt"
import tknz "core:odin/tokenizer"
import "core:os"
import casl "src"

main :: proc() {
	file := os.args[1] if len(os.args) > 1 else ""
	if file == "" {fmt.eprint("No file provided"); os.exit(1)}

	file_contents, err := os.read_entire_file_from_path(file, context.allocator)
	tk: tknz.Tokenizer
	tknz.init(&tk, cast(string)file_contents, "")

	graph: map[string]^casl.Graph_node
	parent: string = ""

	tknz.custom_keyword_tokens = {"true", "false"}

	global_list: [dynamic]string
	key_loop: for {
		casl.debug_print("Parsing first level of key_value pairs")
		key := casl.parse_key_val(&tk, &graph, parent)
		if key == "" {break}

		append(&global_list, key)

	}

	graph[""] = new_clone(casl.Graph_node{data = cast(casl.List)global_list[:]})

	for key, val in casl.iterate_graph(graph) {
		fmt.printfln("key:<%v> val:<%#v>", key, val)
	}

}
