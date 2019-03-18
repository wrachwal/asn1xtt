defmodule ClassTest do
  use ExUnit.Case
  require Dev.ASN

  test "encode/decode StartMessage/object1" do
    home0 = Dev.ASN."StartMessage"(msgId: 'home', content: '')
    home1 = Dev.ASN."StartMessage"(msgId: 'home', content: "Ala")
    assert Dev.encode!(home0) == <<48, 10, 128, 4, 104, 111, 109, 101, 129, 2, 19, 0>>
    assert Dev.encode!(home1) == <<48, 13, 128, 4, 104, 111, 109, 101, 129, 5, 19, 3, 65, 108, 97>>
    assert home0 |> Dev.encode!() |> Dev.decode!(:StartMessage) == home0
    assert home1 |> Dev.encode!() |> Dev.decode!(:StartMessage) == Dev.ASN."StartMessage"(home1, content: 'Ala')
  end

  test "encode/decode StartMessage/object2" do
    remote0 = Dev.ASN."StartMessage"(msgId: 'remote', content: 0)
    remote1 = Dev.ASN."StartMessage"(msgId: 'remote', content: 1)
    assert Dev.encode!(remote0) == <<48, 13, 128, 6, 114, 101, 109, 111, 116, 101, 129, 3, 2, 1, 0>>
    assert Dev.encode!(remote1) == <<48, 13, 128, 6, 114, 101, 109, 111, 116, 101, 129, 3, 2, 1, 1>>
    assert remote0 |> Dev.encode!() |> Dev.decode!(:StartMessage) == remote0
    assert remote1 |> Dev.encode!() |> Dev.decode!(:StartMessage) == remote1
  end
end
