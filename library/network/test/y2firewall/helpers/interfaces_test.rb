#!/usr/bin/env rspec

require_relative "../../test_helper"
require "y2firewall/helpers/interfaces"

class DummyClass
  include Y2Firewall::Helpers::Interfaces
end

describe Y2Firewall::Helpers::Interfaces do
  subject { DummyClass.new }
  let(:external) { Y2Firewall::Firewalld::Zone.new(name: "external") }
  let(:dmz) { Y2Firewall::Firewalld::Zone.new(name: "dmz") }
  let(:firewalld) { Y2Firewall::Firewalld.instance }

  before do
    allow(Yast::NetworkInterfaces).to receive("List").and_return(["eth0", "eth1"])
    allow(Yast::NetworkInterfaces).to receive("GetValue").with("eth0", "NAME").and_return("Intel I217-LM")
    allow(Yast::NetworkInterfaces).to receive("GetValue").with("eth1", "NAME").and_return("Intel I217-LM")
    allow(subject).to receive(:firewalld).and_return(firewalld)
    external.interfaces = ["eth0"]
    dmz.interfaces = []
    firewalld.zones = [dmz, external]
    firewalld.default_zone = "external"
  end

  describe "#interface_zone" do
    it "returns the zone name of the given interface" do
      expect(subject.interface_zone("eth0")).to eql("external")
    end

    it "returns nil if the interface does not belong to any zone" do
      expect(subject.interface_zone("eth1")).to eql(nil)
    end
  end

  describe "#known_interfaces" do
    it "returns a hash with the 'id', 'name' and zone of the current interfaces" do
      expect(subject.known_interfaces)
        .to eql(
          [
            { "id" => "eth0", "name" => "Intel I217-LM", "zone" => "external" },
            { "id" => "eth1", "name" => "Intel I217-LM", "zone" => nil }
          ]
        )
    end
  end

  describe "#default_interfaces" do
    it "returns all the interface names that does not belong explicitly to any zone" do
      expect(subject.default_interfaces).to eql(["eth1"])
    end
  end

  describe "#default_zone" do
    it "returns the Y2Firewall::Firewalld::Zone marked as default in firewalld " do
      expect(subject.default_zone).to eql(external)
    end
  end
end
