RSpec::Matchers.define :be_signed_in do
  match do |page|
    page.has_link?('Sign out')
  end

  failure_message do
    'Expected user to be signed in (should have "Sign out" link), but was not'
  end

  failure_message_when_negated do
    'Expected user not to be signed in, but found "Sign out" link'
  end
end

RSpec::Matchers.define :be_on_page do |expected_path|
  match do |page|
    current_path = page.current_path
    current_path == expected_path
  end

  failure_message do |page|
    "Expected to be on #{expected_path}, but was on #{page.current_path}"
  end
end
