package casl

import "core:fmt"
import tknz "core:odin/tokenizer"
import "core:os"
import "core:strconv"
import "core:strings"

Directive :: struct {
	path: string,
}
List :: distinct []string


Graph_data :: union {
	f64,
	bool,
	i64,
	string,
	Directive,
	List,
	Expression,
}

Graph_node :: struct {
	data:    Graph_data,
	visited: uint,
}
when ODIN_DEBUG {debug_print :: fmt.printfln} else {debug_print :: proc(_: ..any) {}}


directive_strip_last :: proc(dir: string) -> string {
	parts := strings.split(dir, ".")
	last_part_len := len(parts[:len(parts)])
	return dir[:last_part_len]
}


iterate_graph :: proc(g: map[string]^Graph_node) -> (key: string, value: Graph_data, ok: bool) {
	@(static) accum: [dynamic]string
	@(static) state: int = 0
	base_visited := g[""].visited

	debug_print("before outer_loop")
	outer_loop: for {
		switch state {
		case 0:
			{
				list := cast([]string)g[""].data.(List)
				append_elems(&accum, ..list)
				state += 1
				fallthrough
			}

		case:
			{
				if len(accum) == 0 {
					ok = false
					return
				}
				current := accum[0]
				ordered_remove_dynamic_array(&accum, 0)
				ok = true

				data, ok_data := g[current]
				if data.visited != base_visited {
					// skip this one
					continue outer_loop
				} else {data.visited = base_visited + 1}
				key = current
				value = data.data

				if list, is := data.data.(List); is {
					append_elems(&accum, ..cast([]string)list)
				}

				return
			}
		}
	}


	return
}


// parses a single key-value pair
parse_key_val :: proc(
	tk: ^tknz.Tokenizer,
	graph: ^map[string]^Graph_node,
	parent: string,
) -> (
	key: string,
) {

	key = ""

	for {
		token := tknz.scan(tk)
		for token.kind == .Comment {
			// skill all comments
			token = tknz.scan(tk)
		}
		if token.kind == .Ident {
			debug_print("Found identifier:%v", token.text)
			key = token.text if parent == "" else fmt.aprintf("%v.%v", parent, token.text)
			equal := tknz.scan(tk)
			for equal.kind == .Comment {equal = tknz.scan(tk)}
			if equal.kind != .Eq {
				if true do fmt.panicf("(%v)Unexpected token, expected an equal sign, got %v:%v instead", token.pos, token.kind, token.text)
				os.exit(1)
			}

			first_tk := tknz.scan(tk)
			for first_tk.kind == .Comment {first_tk = tknz.scan(tk)}

			if first_tk.kind != .Open_Brace {
				new_node := new_clone(parse_expr(tk, first_tk))
				graph[key] = new_node

			} else {
				list: [dynamic]string
				list_loop: for {

					tk_savepoint := tk^
					first_tk = tknz.scan(tk)
					for first_tk.kind == .Comment {first_tk = tknz.scan(tk)}
					debug_print("Iteration of nested key_value pair, first_tk is:%v", first_tk)
					if first_tk.kind == .Close_Brace {
						debug_print("Found end of nested close_brace, breaking out")

						final_list := list[:]
						new_node := new_clone(Graph_node{data = List(final_list)})
						graph[key] = new_node

						break list_loop
					} else {
						// not finished, restore
						tk^ = tk_savepoint
					}


					nested_key := parse_key_val(tk, graph, key)
					if nested_key != "" do append(&list, nested_key)
					else {panic("didn't think ill get here")}
					// else do break list_loop
				}
			}

			// parse optional leftover comma
			tk_savepoint := tk^
			last_tk := tknz.scan(tk)
			for first_tk.kind == .Comment {first_tk = tknz.scan(tk)}

			if last_tk.kind == .Comma {return}

			// also acceptable to leave out comma at the end of the file
			if last_tk.kind == .EOF {return} else if last_tk.kind == .Close_Brace {
				tk^ = tk_savepoint
				return
			} else {
				if true do fmt.panicf("Expected trailing comma, got %v intead", last_tk)
				os.exit(1)
			}


		} else if token.kind == .EOF {return ""} else {
			if true do fmt.panicf("(%v)Unexpected token, expected an identifier, got %v:%v instead", token.pos, token.kind, token.text)
			os.exit(1)
		}
	}

	fmt.print("was not supposed to reach this")
	os.exit(1)
}

parse_val :: proc(tk: ^tknz.Tokenizer, first: tknz.Token) -> (node: Graph_node) {
	fallow := first
	debug_print("Fallow in parse_val is:%v", fallow)

	#partial switch fallow.kind {
	case .Open_Brace:
		debug_print("No {{ should be in parse_val")
		os.exit(1)
	case .Ident:
		b: strings.Builder
		strings.write_string(&b, fallow.text)
		directives_loop: for {
			tk_savepoint := tk^
			end_tk := tknz.scan(tk)
			for end_tk.kind == .Comment {end_tk = tknz.scan(tk)}


			if end_tk.kind == .Period {
				// period denotes a nested identifier
				strings.write_rune(&b, '.')
				fallow = tknz.scan(tk)
				if fallow.kind != .Ident {
					if true do fmt.panicf("(%v)Expected Identifier, got %v:%v intead", fallow.pos, fallow.kind, fallow.text)
					os.exit(1)
				}

				strings.write_string(&b, fallow.text)

				continue directives_loop
			}

			// parsed too much, restore
			tk^ = tk_savepoint
			break
		} // directive_loop

		full_ident := strings.to_string(b)
		return {data = Directive({full_ident})}


	case .Integer:
		val, _ := strconv.parse_i64(fallow.text, 10)
		return {data = val}
	case .Float:
		val, _ := strconv.parse_f64(fallow.text)
		return {data = val}
	case .String:
		return {data = fallow.text}
	case .Eq, .Period, .Comma, .Close_Brace:
		if true do fmt.panicf("(%v)Unexpected token, expected a value, got %v:%v instead", fallow.pos, fallow.kind, fallow.text)
		os.exit(1)

	case .Invalid:
		if true do fmt.panicf("Invalid token: %v", fallow.text)
		os.exit(1)
	case:
		if .B_Custom_Keyword_Begin < fallow.kind {
			if fallow.text == "true" {
				return {data = true}
			} else if fallow.text == "false" {
				return {data = false}
			} else {
				if true do fmt.panicf("Custom keyword %v not covered in fallow ", fallow.text)
				os.exit(1)
			}
		} else {
			if true do fmt.panicf("Case not covered in fallow :%v", fallow)
			os.exit(1)
		}

	}
}
