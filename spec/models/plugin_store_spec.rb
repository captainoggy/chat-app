require "spec_helper"
require_dependency "plugin_store"

describe PluginStore do
  def set(k,v)
    PluginStore.set("my_plugin", k, v)
  end

  def get(k)
    PluginStore.get("my_plugin", k)
  end

  it "sets strings correctly" do
    set("hello", "world")
    expect(get("hello")).to eq("world")

    set("hello", "world1")
    expect(get("hello")).to eq("world1")
  end

  it "sets fixnums correctly" do
    set("hello", 1)
    expect(get("hello")).to eq(1)
  end

  it "sets bools correctly" do
    set("hello", true)
    expect(get("hello")).to eq(true)

    set("hello", false)
    expect(get("hello")).to eq(false)

    set("hello", nil)
    expect(get("hello")).to eq(nil)
  end


  it "handles hashes correctly" do

    val = {"hi" => "there", "1" => 1}
    set("hello", val)
    result = get("hello")

    expect(result).to eq(val)

    # ensure indiff access holds
    expect(result[:hi]).to eq("there")
  end
end
