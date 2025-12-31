require "rails_helper"

RSpec.describe "Locales", type: :request do
  describe "PATCH /locale" do
    context "when switching to Vietnamese" do
      it "sets locale to vi in session" do
        patch locale_path, params: { locale: "vi" }
        expect(session[:locale]).to eq("vi")
      end

      it "redirects back to referrer" do
        patch locale_path, params: { locale: "vi" }, headers: { "HTTP_REFERER" => root_path }
        expect(response).to redirect_to(root_path)
      end

      it "redirects to root if no referrer" do
        patch locale_path, params: { locale: "vi" }
        expect(response).to redirect_to(root_path)
      end

      it "persists locale across requests" do
        patch locale_path, params: { locale: "vi" }
        get root_path
        expect(I18n.locale).to eq(:vi)
      end
    end

    context "when switching to English" do
      before do
        # Set initial locale to Vietnamese
        patch locale_path, params: { locale: "vi" }
      end

      it "sets locale to en in session" do
        patch locale_path, params: { locale: "en" }
        expect(session[:locale]).to eq("en")
      end

      it "changes locale from vi back to en" do
        patch locale_path, params: { locale: "en" }
        get root_path
        expect(I18n.locale).to eq(:en)
      end
    end

    context "when providing invalid locale" do
      it "falls back to default locale (en)" do
        # Start fresh with no session locale
        patch locale_path, params: { locale: "fr" }
        expect(session[:locale]).to be_nil
      end

      it "does not set invalid locale" do
        # First clear any existing locale, then try invalid
        patch locale_path, params: { locale: "en" }  # Set to en first
        patch locale_path, params: { locale: "invalid" }
        get root_path
        expect(I18n.locale).to eq(:en)
      end

      it "still redirects back" do
        patch locale_path, params: { locale: "fr" }, headers: { "HTTP_REFERER" => root_path }
        expect(response).to redirect_to(root_path)
      end
    end

    context "when locale parameter is missing" do
      it "does not change session" do
        patch locale_path
        expect(session[:locale]).to be_nil
      end

      it "redirects back" do
        patch locale_path, headers: { "HTTP_REFERER" => root_path }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
