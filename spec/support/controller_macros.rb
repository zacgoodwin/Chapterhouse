# frozen_string_literal: true

module ControllerMacros
  def sign_in_user
    before do
      @current_user = create :user
      @request.headers['Authorization'] = "Bearer #{supabase_token_for(@current_user)}"
    end
  end
end
