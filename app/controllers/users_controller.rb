class UsersController < ApplicationController
    before_action :authenticate 

    def top
        @user = current_user
    end

    def update
        current_user.update(user_params)
        LineBotController.change_rich_menu(current_user.line_id, "richmenu-5e99b91c78df5c5307c835b5f18afbaa")
    end

    private
    def user_params
        params.require(:user).permit(:line_id, :home_station, :time_for_station)
    end

    def authenticate
        redirect_to user_line_omniauth_authorize_path unless user_signed_in?     
    end

    
end
