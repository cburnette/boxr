require 'spec_helper'

#rake spec SPEC_OPTS="-e \"invokes search operations"\"
describe 'search operations' do
  it "invokes search operations" do
    #the issue with this test is that Box can take between 5-10 minutes to index any content uploaded; this is just a smoke test
    #so we are searching for something that should return zero results
    puts "perform search"
    results = BOX_CLIENT.search("sdlfjuwnsljsdfuqpoiqweouyvnnadsfkjhiuweruywerbjvhvkjlnasoifyukhenlwdflnsdvoiuawfydfjh")
    expect(results).to eq([])
  end
end
