type label = string
type instr =
  | Cst(int)
  | Add
  | Mul
  | Var(int)
  | Pop
  | Swap
  | Label(label)
  | Call(label, int)
  | Ret(int)
  | Goto(label)
  | IfZero(label)
  | Exit

let initArray = (length: int) => {
  let array = []
  for _ in 1 to length {
    let _ = Js.Array.push(0, array)
  }
  array
}

let size_of_instr = (instr: instr): int => {
  switch instr {
  | Add | Mul | Pop | Swap | Exit => 1
  | Cst(_) | Var(_) | Ret(_) | IfZero(_) | Goto(_) => 2
  | Call(_, _) => 3
  | Label(_) => 0
  }
}

let encode = (instrs: array<instr>): array<int> => {
  let int_code: array<int> = Belt.Array.make(114514, 0)
  let label_map = Belt.Map.String.empty
  let getExn = Belt.Option.getExn
  let position = ref(0)
  for cur in 0 to Belt.Array.length(instrs) - 1 {
    switch instrs[cur] {
    | Label(l) =>
      let _ = Belt.Map.String.set(label_map, l, position.contents)
    | instr => position := position.contents + size_of_instr(instr)
    }
  }
  position.contents = 0
  for cur in 0 to Belt.Array.length(instrs) - 1 {
    switch instrs[cur] {
    | Cst(i) => {
        int_code[position.contents] = 0
        int_code[position.contents + 1] = i
        position := position.contents + size_of_instr(instrs[cur])
      }
    | Add => {
        int_code[position.contents] = 1
        position := position.contents + size_of_instr(instrs[cur])
      }
    | Mul => {
        int_code[position.contents] = 2
        position := position.contents + size_of_instr(instrs[cur])
      }
    | Var(i) => {
        int_code[position.contents] = 3
        int_code[position.contents + 1] = i
        position := position.contents + size_of_instr(instrs[cur])
      }
    | Pop => {
        int_code[position.contents] = 4
        position := position.contents + size_of_instr(instrs[cur])
      }
    | Swap => {
        int_code[position.contents] = 5
        position := position.contents + size_of_instr(instrs[cur])
      }
    | Call(l, n) => {
        let label_addr = Belt.Map.String.get(label_map, l)
        int_code[position.contents] = 6
        int_code[position.contents + 1] = getExn(label_addr)
        int_code[position.contents + 2] = n
        position := position.contents + size_of_instr(instrs[cur])
      }
    | Ret(n) => {
        int_code[position.contents] = 7
        int_code[position.contents + 1] = n
        position := position.contents + size_of_instr(instrs[cur])
      }
    | IfZero(l) => {
        let label_addr = Belt.Map.String.get(label_map, l)
        int_code[position.contents] = 8
        int_code[position.contents + 1] = getExn(label_addr)
        position := position.contents + size_of_instr(instrs[cur])
      }
    | Goto(l) => {
        let label_addr = Belt.Map.String.get(label_map, l)
        int_code[position.contents] = 9
        int_code[position.contents + 1] = getExn(label_addr)
        position := position.contents + size_of_instr(instrs[cur])
      }
    | Exit => {
        int_code[position.contents] = 10
        position := position.contents + size_of_instr(instrs[cur])
      }
    | Label(_) => ()
    }
  }
  int_code
}

module VM = {
  type operand = int
  type vm = {
    code: array<int>,
    stack: array<operand>,
    mutable pc: int,
    mutable sp: int,
  }
  let push = (vm: vm, x: operand) => {
    vm.stack[vm.sp] = x
    vm.sp = vm.sp + 1
  }
  let pop = (vm: vm): operand => {
    vm.sp = vm.sp - 1
    vm.stack[vm.sp]
  }
  let initVM = code => {
    code,
    stack: Belt.Array.make(10, 0),
    pc: 0,
    sp: 0,
  }
  let run = (vm: vm): operand => {
    let break = ref(false)
    while !break.contents {
      let opcode = vm.code[vm.pc]
      switch opcode {
      | 0 => {
          let const = vm.code[vm.pc + 1]
          push(vm, const)
          vm.pc = vm.pc + 2
        }
      | 1 => {
          push(vm, pop(vm) + pop(vm))
          vm.pc = vm.pc + 1
        }
      | 2 => {
          push(vm, pop(vm) * pop(vm))
          vm.pc = vm.pc + 1
        }
      | 3 => {
          let index = vm.code[vm.pc + 1]
          push(vm, vm.stack[vm.sp - 1 - index])
          vm.pc = vm.pc + 2
        }
      | 4 => {
          let _ = pop(vm)
          vm.pc = vm.pc + 1
        }
      | 5 => {
          let a = pop(vm)
          let b = pop(vm)
          push(vm, b)
          push(vm, a)
          vm.pc = vm.pc + 1
        }
      | 6 => {
          let target_pc = vm.code[vm.pc + 1]
          let arity = vm.code[vm.pc + 2]
          let next_pc = target_pc
          // Insert the return address
          let _ = Js.Array.spliceInPlace(~pos=vm.sp - arity, ~remove=0, ~add=[vm.pc + 3], vm.stack)
          vm.sp = vm.sp + 1
          vm.pc = next_pc
        }
      | 7 => {
          let arity = vm.code[vm.pc + 1]
          let res = pop(vm)
          vm.sp = vm.sp - arity
          let next_pc = pop(vm)
          let _ = push(vm, res)
          vm.pc = next_pc
        }
      | 8 =>
        if pop(vm) === 0 {
          vm.pc = vm.code[vm.pc + 1]
        } else {
          vm.pc = vm.pc + 2
        }
      | 9 => vm.pc = vm.code[vm.pc + 1]
      | 10 => break := true
      | _ => assert false
      }
    }
    pop(vm)
  }
}
