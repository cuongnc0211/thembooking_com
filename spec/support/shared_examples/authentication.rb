RSpec.shared_examples 'requires authentication' do |redirect_path = nil|
  it 'redirects to sign in page when not authenticated' do
    visit path

    expect(page).to have_current_path(new_session_path)
    expect(page).to have_content('Sign in')
  end

  it 'allows access after signing in' do
    user = create(:user)

    visit path

    # Redirected to sign in
    expect(page).to have_current_path(new_session_path)

    # Sign in
    fill_in 'Email', with: user.email_address
    fill_in 'Password', with: 'password123'
    click_button 'Sign in'

    # Should redirect back to original path or specified redirect_path
    expect(page).to have_current_path(redirect_path || path, ignore_query: true)
  end
end

RSpec.shared_examples 'accessible without authentication' do
  it 'allows access without signing in' do
    visit path

    expect(page).not_to have_current_path(new_session_path)
  end
end
