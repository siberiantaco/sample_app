module SessionsHelper
  def log_in(user)
    session[:user_id] = user.id
  end
  
  def log_out
    forget(current_user)
    session.delete(:user_id)
    @current_user = nil
  end
  
  def current_user
    if id = session[:user_id]
      @current_user ||= User.find_by(id: id)
    elsif id = cookies.signed[:user_id]
      user = User.find_by(id: id)
      if user && user.authenicated?(cookies[:remember_token])
        @current_user ||= user
      end
    end
  end
  
  def logged_in?
    !current_user.nil?
  end
  
  def remember(user)
    user.remember
    cookies.permanent.signed[:user_id] = user.id
    cookies.permanent[:remember_token] = user.remember_token
  end
  
  def forget(user)
    user.forget
    cookies.delete(:remember_token)
    cookies.delete(:user_id)
  end

end