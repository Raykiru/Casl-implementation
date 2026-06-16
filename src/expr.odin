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

parse_expr :: proc(tk: ^tknz.Tokenizer, first: tknz.Token) -> (node: Graph_node) {

	node = parse_val(tk, first)

	tk_savepoint := tk^

	fallow := tknz.scan(tk)

	#partial switch fallow.kind {
	case .Quo:
		{
			left := Unit(new_clone(node))
			fallow = tknz.scan(tk)
			right_node := parse_val(tk, fallow)
			#partial switch node in right_node.data {
			// allowed to be the right
			case f64, i64:
				// matches type
				if _, is := node.(f64); is {
					if _, is2 := right_node.data.(f64); is2 {
						right := Unit(new_clone(right_node))
						return Graph_node{Bin_expr{.DIV, left, right}, false}
					}
				} else if _, is := node.(i64); is {
					if _, is2 := right_node.data.(i64); is2 {
						right := Unit(new_clone(right_node))
						return Graph_node{Bin_expr{.DIV, left, right}, false}
					}
				} else {

					if true do fmt.panicf("Imcompatible types for binary div: %#v %#v", node, right_node.data)
					os.exit(1)
				}
			case Directive:
				// always allowed, will be checked on dereference
				right := Unit(new_clone(right_node))
				return Graph_node{Bin_expr{.DIV, left, right}, false}


			}
		}
	case .Mul:
		{
			left := Unit(new_clone(node))
			fallow = tknz.scan(tk)
			right_node := parse_val(tk, fallow)
			#partial switch node in right_node.data {
			// allowed to be the right
			case f64, i64:
				// matches type
				if _, is := node.(f64); is {
					if _, is2 := right_node.data.(f64); is2 {
						right := Unit(new_clone(right_node))
						return Graph_node{Bin_expr{.MUL, left, right}, false}
					}
				} else if _, is := node.(i64); is {
					if _, is2 := right_node.data.(i64); is2 {
						right := Unit(new_clone(right_node))
						return Graph_node{Bin_expr{.MUL, left, right}, false}
					}
				} else {

					if true do fmt.panicf("Imcompatible types for binary mul: %#v %#v", node, right_node.data)
					os.exit(1)
				}
			case Directive:
				// always allowed, will be checked on dereference
				right := Unit(new_clone(right_node))
				return Graph_node{Bin_expr{.MUL, left, right}, false}


			}
		}
	case .Sub:
		{
			left := Unit(new_clone(node))
			fallow = tknz.scan(tk)
			right_node := parse_val(tk, fallow)
			#partial switch node in right_node.data {
			// allowed to be the right
			case f64, i64:
				// matches type
				if _, is := node.(f64); is {
					if _, is2 := right_node.data.(f64); is2 {
						right := Unit(new_clone(right_node))
						return Graph_node{Bin_expr{.SUB, left, right}, false}
					}
				} else if _, is := node.(i64); is {
					if _, is2 := right_node.data.(i64); is2 {
						right := Unit(new_clone(right_node))
						return Graph_node{Bin_expr{.SUB, left, right}, false}
					}
				} else {

					if true do fmt.panicf("Imcompatible types for binary sub: %#v %#v", node, right_node.data)
					os.exit(1)
				}
			case Directive:
				// always allowed, will be checked on dereference
				right := Unit(new_clone(right_node))
				return Graph_node{Bin_expr{.SUB, left, right}, false}


			}
		}

	case .Add:
		{
			left := Unit(new_clone(node))
			fallow = tknz.scan(tk)
			right_node := parse_val(tk, fallow)
			#partial switch node in right_node.data {
			// allowed to be the right
			case f64, i64:
				// matches type
				if _, is := node.(f64); is {
					if _, is2 := right_node.data.(f64); is2 {
						right := Unit(new_clone(right_node))
						return Graph_node{Bin_expr{.ADD, left, right}, false}
					}
				} else if _, is := node.(i64); is {
					if _, is2 := right_node.data.(i64); is2 {
						right := Unit(new_clone(right_node))
						return Graph_node{Bin_expr{.ADD, left, right}, false}
					}
				} else {

					if true do fmt.panicf("Imcompatible types for binary add: %#v %#v", node, right_node.data)
					os.exit(1)
				}
			case Directive:
				// always allowed, will be checked on dereference
				right := Unit(new_clone(right_node))
				return Graph_node{Bin_expr{.ADD, left, right}, false}


			}
		}

	case .Comma:
		// allowed to be, just restore
		tk^ = tk_savepoint
	case:
		if true do fmt.panicf("Unhandled token kind for fallow in parse_expr: %v (%v)", fallow.kind, fallow.text)
		os.exit(1)
	}

	return
}
