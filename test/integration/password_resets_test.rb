require 'test_helper'

class PasswordResetsTest < ActionDispatch::IntegrationTest
  
  def setup
    @user = users(:michael)
    ActionMailer::Base.deliveries.clear
  end
  
  test "expired token" do
    get new_password_reset_path
    post password_resets_path, password_reset: {email: @user.email}
    user = assigns(:user)
    user.update_attribute(:reset_sent_at, 3.hours.ago)
    patch password_reset_path(user.reset_token), email: @user.email, 
                                                user: 
                                                  {
                                                    password: "foobaz", 
                                                  password_confirmation: "foobaz" 
                                                    
                                                  }
                                                  
    assert_response :redirect
    #follow_redirect!
    #assert_match /expired/, response.body
  end
  
  test "reset password" do
    get new_password_reset_path
    assert_template 'password_resets/new'
    #invalid mail
    post password_resets_path, password_reset: {email: ""}
    assert_not flash.empty?
    assert_template 'password_resets/new'
    #valid mail
    post password_resets_path, password_reset: {email: @user.email}
    assert_not_equal @user.reset_digest, @user.reload.reset_digest
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_not flash.empty?
    assert_redirected_to root_url
    #password changing form
    user = assigns(:user)
    #wrong email
    get edit_password_reset_url(user.reset_token, email: "")
    assert_redirected_to root_url
    #inactive user
    user.toggle!(:activated)
    get edit_password_reset_url(user.reset_token, email: user.email)
    assert_redirected_to root_url
    user.toggle!(:activated)
    #Right email, wrong token
    get edit_password_reset_url("invalid token", email: user.email)
    assert_redirected_to root_url
    #Right email, right token
    get edit_password_reset_path(user.reset_token, email: user.email)
    assert_template 'password_resets/edit'
    assert_select "input[name=email][type=hidden][value=?]", user.email
    # Blank password
    patch password_reset_path(user.reset_token), email: user.email, 
                                                user: {password: " ", 
                                                password_confirmation: "foobar" }
    assert_not flash.empty?
    assert_template 'password_resets/edit'
    # Valid password & confirmation
    patch password_reset_path(user.reset_token), email: user.email, 
                                                user: {password: "foobaz", 
                                                password_confirmation: "foobaz" }
    assert is_logged_in?
    assert_not flash.empty?
    assert_redirected_to user
  end
end
