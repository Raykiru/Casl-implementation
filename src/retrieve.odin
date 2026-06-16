package casl

import "core:fmt"
import "core:os"
import "core:reflect"
import "core:strings"

Retrive_error :: enum {
	None,
	Circular_graph,
	Path_not_found,
	Type_Missmatch,
	Unsuported_types_for_binop,
}

get_value :: proc(
	graph: map[string]^Graph_node,
	key: string,
) -> (
	data: Graph_data,
	err: Retrive_error,
) {
	key := key
	base_visited := graph[""].visited

	outer_loop: for {
		node, found := graph[key]

		if !found {
			err = .Path_not_found
			return
		}

		data = node.data

		if node.visited > base_visited {
			// cycle detected
			err = .Circular_graph
			return
		}
		#partial switch inner in data {
		case Directive:
			key = inner.path
			node.visited = base_visited + 1
		case Expression:
			switch expr in inner {
			case Bin_expr:
				{
					left_unit, right_unit: Graph_data
					left, right := expr.left, expr.right


					if left_directive, left_is_directive := expr.left.(Directive);
					   left_is_directive {
						left_unit = get_value(graph, left_directive.path) or_return
						left = cast(Unit)(&left_unit)
					}


					if right_directive, right_is_directive := expr.right.(Directive);
					   right_is_directive {
						right_unit = get_value(graph, right_directive.path) or_return
						right = cast(Unit)(&right_unit)
					}

					matches :=
						reflect.get_union_variant_raw_tag((cast(^Graph_data)left)^) ==
						reflect.get_union_variant_raw_tag((cast(^Graph_data)right)^)

					if !matches {
						err = .Type_Missmatch
						return
					}


					// pain
					switch expr.kind {
					case .ADD:
						#partial switch left_val in left {
						case f64:
							data = left_val + right.(f64)
						case i64:
							data = left_val + right.(i64)
						case string:
							b: strings.Builder
							strings.write_string(&b, left_val[:len(left_val) - 1])
							strings.write_string(&b, right.(string)[1:])
							data = strings.to_string(b)
							return
						case:
							err = .Unsuported_types_for_binop
							return
						}

					case .SUB:
						#partial switch left_val in left {
						case f64:
							data = left_val - right.(f64)
						case i64:
							data = left_val - right.(i64)
						case:
							err = .Unsuported_types_for_binop
						}
					case .MUL:
						#partial switch left_val in left {
						case f64:
							data = left_val * right.(f64)
						case i64:
							data = left_val * right.(i64)
						case:
							err = .Unsuported_types_for_binop
							return
						}
					case .DIV:
						#partial switch left_val in left {
						case f64:
							data = left_val / right.(f64)
						case i64:
							data = left_val / right.(i64)
						case:
							err = .Unsuported_types_for_binop
						}

					case:
						fmt.panicf("Unexpected union varient for expression kind: %v", expr.kind)
					}

					return

				}
			case Un_expr:
				// no unary expression defied yet
				fmt.panicf("TODO: Unimplemented")
			}

		case:
			break outer_loop
		}
	}


	return
}
