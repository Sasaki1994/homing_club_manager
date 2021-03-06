class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def line; basic_action end

    private

    def basic_action
        omniauth = request.env['omniauth.auth']
        @user = User.find_by(line_id: omniauth['uid'])
        p omniauth['uid']
        line_id = omniauth['uid']
        @user = User.create(line_id: line_id) unless @user.present?
        sign_in(@user)
        redirect_to root_path    
    end


end
