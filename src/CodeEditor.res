module SMoLCodeMirror = {
  @react.component @module("./my-code-mirror")
  external make: (~value: string, ~onChange: string => ()) => React.element = "default"
}

@react.component
let make = (~program, ~setProgram) => {
  // let output = switch S_expr.parse_many(program |> S_expr.stringToSource) {
  // | parsed => S_expr.stringOfManySexprs(parsed)
  // | exception S_expr.WantSExprFoundEOF => "Unexpected EOF while looking for an S-expression."
  // | exception S_expr.WantStringFoundEOF => "Unexpected EOF while processing a string."
  // | exception S_expr.WantEscapableCharFound(string) =>
  //   `This character (${string}) can't be escaped.`
  // | exception S_expr.WantSExprFoundRP(_source) => "Unexpected right parenthesis."
  // }
  let onChange = s => {
    setProgram(_ => s)
  }
  // <div>
  <SMoLCodeMirror
    value=program
    onChange={onChange}
  />
  // <textarea value=program onChange disabled={!editable} rows=17 cols=30 />
  // <p> {React.string(output)} </p>
  // </div>
}
