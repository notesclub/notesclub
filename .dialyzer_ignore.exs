[
  # False positives: Ecto.Multi.new/0 return violates Multi's opaque type
  # under OTP 29 dialyzer
  {"lib/notesclub/accounts.ex", "Type mismatch in call without opaque term in insert."},
  {"lib/notesclub/repos.ex", "Type mismatch in call without opaque term in insert."}
]
