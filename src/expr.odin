package casl

import "core:fmt"
import tknz "core:odin/tokenizer"
import "core:os"

Unit :: distinct ^Graph_data

Un_expr_kind :: enum {}

Un_expr :: struct {
	kind: Un_expr_kind,
	data: Unit,
}


Bin_expr_kind :: enum {
	ADD,
	SUB,
	MUL,
	DIV,
}

Bin_expr :: struct {
	kind:  Bin_expr_kind,
	left:  Unit,
	right: Unit,
}

Expression :: union {
	Un_expr,
	Bin_expr,
}

parse_expr :: proc(
	tk: ^tknz.Tokenizer,
	first: tknz.Token,
) -> (
	node: Graph_node,
	err: Parse_error,
) {

	node = parse_val(tk, first) or_return

	tk_savepoint := tk^

	fallow := tknz.scan(tk)

	#partial switch fallow.kind {
	case .Quo:
		{
			left_expr := Unit(new_clone(node))
			fallow = tknz.scan(tk)
			right_node := parse_val(tk, fallow) or_return
			#partial switch right in right_node.data {
			// allowed to be the right
			case f64, i64:
				missmatch := true
				// matches type
				if _, is := node.data.(f64);
				   is {if _, is2 := right_node.data.(f64); is2 {missmatch = false}
				} else if _, is := node.data.(i64);
				   is {if _, is2 := right_node.data.(i64); is2 {missmatch = false}
				} else if _, is := node.data.(Directive); is {missmatch = false}

				if missmatch {
					err = cast(Err_Type_Missmatch)fmt.aprintf(
						"Imcompatible types for binary div: %#v %#v",
						node,
						right_node.data,
					)
					return
				}

				right_expr := Unit(new_clone(right_node))
				return Graph_node{data = Bin_expr{.DIV, left_expr, right_expr}}, nil
			case Directive:
				// always allowed, will be checked on dereference
				right_expr := Unit(new_clone(right_node.data))
				return Graph_node{data = Bin_expr{.DIV, left_expr, right_expr}}, nil
			case:
				err = cast(Err_Type_Missmatch)fmt.aprintf(
					"Unsuported types for binary div: %#v %#v",
					node,
					right_node.data,
				)

				return
			}
		}
	case .Mul:
		{
			left_expr := Unit(new_clone(node))
			fallow = tknz.scan(tk)
			right_node := parse_val(tk, fallow) or_return
			missmatch := true
			#partial switch right in right_node.data {
			// allowed to be the right
			case f64, i64:
				{
					// matches type
					if _, is := node.data.(f64); is {
						if _, is2 := right_node.data.(f64); is2 {missmatch = false}
					} else if _, is := node.data.(i64); is {
						if _, is2 := right_node.data.(i64); is2 {missmatch = false}
					} else if _, is := node.data.(Directive); is {missmatch = false}

					if missmatch {
						err = cast(Err_Type_Missmatch)fmt.aprintf(
							"Imcompatible types for binary mul: %#v %#v",
							node,
							right_node.data,
						)
						return
					}
					right_expr := Unit(new_clone(right_node))
					return Graph_node{data = Bin_expr{.MUL, left_expr, right_expr}}, nil
				}
			case Directive:
				// always allowed, will be checked on dereference
				right_expr := Unit(new_clone(right_node))
				return Graph_node{data = Bin_expr{.MUL, left_expr, right_expr}}, nil
			case:
				err = cast(Err_Type_Missmatch)fmt.aprintf(
					"Unsuported types for binary mul: %#v %#v",
					node,
					right_node.data,
				)
				return
			}
		}
	case .Sub:
		{
			left := Unit(new_clone(node))
			fallow = tknz.scan(tk)
			right_node := parse_val(tk, fallow) or_return

			missmatch := true

			#partial switch right in right_node.data {
			// allowed to be the right
			case f64, i64:
				// matches type
				if _, is := node.data.(f64); is {
					if _, is2 := right_node.data.(f64); is2 {missmatch = false}
				} else if _, is := node.data.(i64); is {
					if _, is2 := right_node.data.(i64); is2 {missmatch = false}
				} else if _, is := node.data.(Directive); is {missmatch = false}

				if missmatch {
					err = cast(Err_Type_Missmatch)fmt.aprintf(
						"Imcompatible types for binary sub: %#v %#v",
						node,
						right_node.data,
					)
					return
				}

				right_expr := Unit(new_clone(right_node))
				return Graph_node{data = Bin_expr{.SUB, left, right_expr}}, nil
			case Directive:
				// always allowed, will be checked on dereference
				right_expr := Unit(new_clone(right_node))
				return Graph_node{data = Bin_expr{.SUB, left, right_expr}}, nil
			case:
				err = cast(Err_Type_Missmatch)fmt.aprintf(
					"Unsuported types for binary sub: %#v %#v",
					node,
					right_node.data,
				)
				return
			}
		}

	case .Add:
		{
			left := Unit(new_clone(node))
			fallow = tknz.scan(tk)
			right_node := parse_val(tk, fallow) or_return
			missmatch := true

			#partial switch right in right_node.data {
			// allowed to be the right
			case f64, i64:
				// matches type
				if _, is := node.data.(f64); is {
					if _, is2 := right_node.data.(f64); is2 {missmatch = false}
				} else if _, is := node.data.(i64); is {
					if _, is2 := right_node.data.(i64); is2 {missmatch = false}
				} else if _, is := node.data.(Directive); is {missmatch = false}

				if missmatch {
					err = cast(Err_Type_Missmatch)fmt.aprintf(
						"Imcompatible types for binary add: %#v %#v",
						node.data,
						right_node.data,
					)
					return
				}

				right_expr := Unit(new_clone(right_node))
				return Graph_node{data = Bin_expr{.ADD, left, right_expr}}, nil
			case Directive:
				// always allowed, will be checked on dereference
				right_expr := Unit(new_clone(right_node))
				return Graph_node{data = Bin_expr{.ADD, left, right_expr}}, nil
			case string:
				// matches type
				if _, is := node.data.(f64); is {
					if _, is2 := right_node.data.(f64); is2 {missmatch = false}
				} else if _, is := node.data.(i64); is {
					if _, is2 := right_node.data.(i64); is2 {missmatch = false}
				} else if _, is := node.data.(Directive); is {missmatch = false}

				if missmatch {
					err = cast(Err_Type_Missmatch)fmt.aprintf(
						"Imcompatible types for binary add: %#v %#v",
						node,
						right_node.data,
					)
					return
				}

				right_expr := Unit(new_clone(right_node))
				return Graph_node{data = Bin_expr{.ADD, left, right_expr}}, nil
			case:
				err = cast(Err_Type_Missmatch)fmt.aprintf(
					"Unexpected types for binary add: %#v %#v",
					node,
					right_node.data,
				)
				return


			}
		}

	case .Comma:
		// allowed to be, just restore
		tk^ = tk_savepoint
	case:
		err = cast(Err_Type_Missmatch)fmt.aprintf(
			"Unhandled token kind for fallow in parse_expr: %v (%v)",
			fallow.kind,
			fallow.text,
		)
		return
	}

	return
}
