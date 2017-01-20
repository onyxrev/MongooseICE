defmodule Fennec.UDPTest do
  use ExUnit.Case

  alias Jerboa.Format
  alias Jerboa.Format.Body.Attribute
  alias Jerboa.Format.Body.Attribute.XORMappedAddress

  @recv_timeout 5000

  describe "binding request" do
    test "returns response with IPv4 XOR mapped address attribute" do
      server_port = 21212
      server_address = {127, 0, 0, 1}
      client_port = 34343
      client_address = {127, 0, 0, 1}
      Fennec.UDP.start_link(server_port)
      id = :crypto.strong_rand_bytes(12)
      req = binding_request(id)

      {:ok, sock} = :gen_udp.open(client_port, [:binary, active: false, ip: client_address])
      :ok = :gen_udp.send(sock, server_address, server_port, req)

      assert {:ok, {^server_address, ^server_port, resp}} = :gen_udp.recv(sock, 0, @recv_timeout)
      :gen_udp.close(sock)
      params = Format.decode!(resp)
      assert %Format{class: :success, method: :binding, identifier: ^id, attributes: [a]} = params
      assert %Attribute{name: XORMappedAddress, value: v} = a
      assert %XORMappedAddress{address: ^client_address, port: ^client_port, family: :ipv4} = v
    end
  end

  defp binding_request(id) do
    %Format{class: :request, method: :binding, identifier: id} |> Format.encode()
  end
end
