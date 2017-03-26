defmodule AsnCttTest do
  use ExUnit.Case
# doctest AsnCtt

  alias ASN.{CTT, RRC}

  test "RRC db" do
    assert is_map(db = RRC.db)
    assert map_size(db) == 1704
    assert is_map(cnt = CTT.asn_type_use(db))
    assert map_size(cnt) == 1569
    singles = cnt |> Enum.filter(fn {_, v} -> v == 1 end) |> Keyword.keys
    assert length(singles) == 238
  # IO.inspect singles |> Enum.sort(), limit: 1000
    assert :TimeAlignmentTimer in singles
  end

end
