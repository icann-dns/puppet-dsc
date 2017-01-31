require 'spec_helper_acceptance'

describe 'dsc class' do
  describe 'running puppet code' do
    it 'work with no errors' do
      pp = 'class {\'::dsc\': }'
      apply_manifest(pp, catch_failures: true)
      expect(apply_manifest(pp, catch_failures: true).exit_code).to eq 0
    end
  end
end
