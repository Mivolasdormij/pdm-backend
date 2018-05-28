class Provider < ApplicationRecord


  belongs_to :parent , foreign_key: :parent_id, class_name: self.name

  validates_presence_of :name, :base_endpoint

  def generate_auth_url(params={})
    if provider_type == "smart"
        generate_fhir_auth_url(params)
    else
       generate_generic_auth_url(params)
     end
  end

  def generate_fhir_auth_url(params={})
    options = get_endpoint_params || discover_fhir_endpoint_params
    options[:site]=base_endpoint
    options[:raise_errors]=true
    generate_oauth_auth_url(options, get_auth_params(params))
  end

  def generate_generic_auth_url(params={})
    options = get_endpoint_params
    options[:site]=base_endpoint
    options[:raise_errors]=true
    generate_oauth_auth_url(options, get_auth_params(params))
  end

  def generate_oauth_auth_url(client_options, auth_params )
    client = OAuth2::Client.new(client_id, client_secret, client_options)
    client.auth_code.authorize_url(auth_params)
  end

  private

  def get_auth_params(params={})
    {aud: base_endpoint,
      redirect_uri: "http://localhost:8080/callback" ,
      scopes: scopes}.merge params
  end

  def get_endpoint_params
    if token_endpoint && authorization_endpoint
      {authorize_url: authorization_url,
       token_uri: token_url }
    end
  end

  def discover_fhir_endpoint_params
    client = FHIR::Client.new(base_endpoint)
    client.default_json
    options = client.get_oauth2_metadata_from_conformance
  end

end