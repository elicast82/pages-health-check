# frozen_string_literal: true

require "spec_helper"

RSpec.describe(GitHubPages::HealthCheck::CAA) do
  let(:domain) { "foo.sub.githubtest.com" }
  let(:parent_domain) { "sub.githubtest.com" }
  subject { described_class.new(domain) }
  let(:caa_packet_le) do
    Dnsruby::RR.create("sub.githubtest.com. IN CAA 0 issue \"letsencrypt.org\"")
  end
  let(:caa_packet_le_apex) do
    Dnsruby::RR.create("githubtest.com. IN CAA 0 issue \"digicert.com\"")
  end
  let(:caa_packet_other) do
    Dnsruby::RR.create("#{domain}. IN CAA 0 issue \"digicert.com\"")
  end

  context "a domain without CAA records" do
    before(:each) do
      expect(subject).to receive(:query).with(domain).and_return([])
    end

    it "knows no records exist" do
      expect(subject).not_to be_records_present
    end

    it "allows let's encrypt" do
      expect(subject).to be_lets_encrypt_allowed
    end

    it "does not encounter an error" do
      expect(subject).not_to be_errored
    end
  end

  context "a domain with LE CAA record" do
    before(:each) do
      expect(subject).to receive(:query).with(domain).and_return([])
    end

    it "knows records exist" do
      expect(subject).to be_records_present
    end

    it "allows let's encrypt" do
      expect(subject).to be_lets_encrypt_allowed
    end

    it "does not encounter an error" do
      expect(subject).not_to be_errored
    end
  end

  context "a domain without LE CAA record" do
    before(:each) do
      expect(subject).to receive(:query).with(domain).and_return([caa_packet_other])
    end

    it "knows records exist" do
      expect(subject).to be_records_present
    end

    it "doesn't let's encrypt" do
      expect(subject).not_to be_lets_encrypt_allowed
    end

    it "does not encounter an error" do
      expect(subject).not_to be_errored
    end
  end

  context "a sub-subdomain with an apex CAA record" do
    before(:each) do
      expect(subject).to receive(:query).with(domain).and_return([])
    end

    it "knows no records exist" do
      expect(subject).not_to be_records_present
    end

    it "allows let's encrypt" do
      expect(subject).to be_lets_encrypt_allowed
    end

    it "does not encounter an error" do
      expect(subject).not_to be_errored
    end
  end

  context "a domain which errors" do
    before(:each) do
      expect(subject).to receive(:query).with(domain).and_return([])
      subject.instance_variable_set(:@error, Dnsruby::ServFail.new)
    end

    it "knows no records exist" do
      expect(subject).not_to be_records_present
    end

    it "doesn't allows let's encrypt" do
      expect(subject).not_to be_lets_encrypt_allowed
    end

    it "surfaces the error" do
      expect(subject).to be_errored
      expect(subject.error.class.name).to eql("Dnsruby::ServFail")
    end
  end

  context "a domain with a parent domain" do
    it "allows no records" do
      expect(subject).to receive(:query).with(parent_domain).and_return([])
      expect(subject.parent_domain_allows_lets_encrypt?).to be_truthy
    end

    it "allows an LE record" do
      expect(subject).to receive(:query).with(parent_domain).and_return([caa_packet_other, caa_packet_le])
      expect(subject.parent_domain_allows_lets_encrypt?).to be_truthy
    end

    it "disallows when no LE record is present" do
      expect(subject).to receive(:query).with(parent_domain).and_return([caa_packet_other])
      expect(subject.parent_domain_allows_lets_encrypt?).to be_falsey
    end

  end
end
