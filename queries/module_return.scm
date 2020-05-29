(
  (program
    (variable_declaration
      variable: (variable_declarator)? @variable)
    (module_return_statement (table (field (identifier) @exported (identifier) @defined))))

  (#eq? @defined @variable)
)

(
  (program
    (variable_declaration
        variable: (field_expression (identifier) @variable))

    (module_return_statement
      (table (field (identifier) @exported (identifier) @defined)))
  )

  (#eq? @variable @defined)
)
