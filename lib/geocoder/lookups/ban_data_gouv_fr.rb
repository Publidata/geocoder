require 'geocoder/lookups/base'
require 'geocoder/results/ban_data_gouv_fr'

module Geocoder::Lookup
  class BanDataGouvFr < Base

    def name
      "Base Adresse Nationale Française"
    end

    def map_link_url(coordinates)
      "https://www.openstreetmap.org/#map=19/#{coordinates.join('/')}"
    end

    def query_url(query)
      method = query.reverse_geocode? ? "reverse" : "search"
      "#{protocol}://api-adresse.data.gouv.fr/#{method}/" + url_query_string(query)
    end

    private # ---------------------------------------------------------------

    def valid_response?(response)
      super(response) && fetch_data(query)['results']['features'].any?
    end

    def results(query)
      return [] unless doc = fetch_data(query)
      if valid_response?(response)
        result = doc
      else
        result = []
        raise_error(Geocoder::Error) ||
            warn("Geportail.lu Geocoding API error")
      end
      result
    end

    #### PARAMS ####

    def query_url_params(query)
      query_ban_datagouv_fr_params(query).merge(super)
    end

    def query_ban_datagouv_fr_params(query)
      query.reverse_geocode? ? reverse_geocode_ban_fr_params(query) : search_geocode_ban_fr_params(query)
    end

    #### SEARCH GEOCODING PARAMS ####
    #
    #  :limit (default = 5)
    #  :autocomplete (default = 0)
    #  :lat (required)
    #  :lon (required)
    #  :type
    #  :postcode
    #  :citycode
    #
    def search_geocode_ban_fr_params(query)
      params = {
        q: query.sanitized_text
      }
      unless (limit = query.options[:limit]).nil? || !limit_param_is_valid?(limit)
        params[:limit] = limit.to_i
      end
      unless (autocomplete = query.options[:autocomplete]).nil? || !autocomplete_param_is_valid?(autocomplete)
        params[:autocomplete] = autocomplete.to_s
      end
      unless (type = query.options[:type]).nil? || !type_param_is_valid?(type)
        params[:type] = type.downcase
      end
      unless (postcode = query.options[:postcode]).nil? || !code_param_is_valid?(postcode)
        params[:postcode] = postcode.to_s
      end
      unless (citycode = query.options[:citycode]).nil? || !code_param_is_valid?(citycode)
        params[:citycode] = citycode.to_s
      end
      params
    end

    #### REVERSE GEOCODING PARAMS ####
    #
    #  :lat (required)
    #  :lon (required)
    #  :type
    #
    def reverse_geocode_ban_fr_params(query)
      lat_lon = query.coordinates
      params = {
          lat: lat_lon.first,
          lon: lat_lon.last
      }
      unless (type = query.options[:type]).nil? || !type_param_is_valid?(type)
        params[:type] = type.downcase
      end
      params
    end

    def limit_param_is_valid?(param)

    end

    def autocomplete_param_is_valid?(param)
      param.to_i == 0 || param.to_i == 1
    end

    def type_param_is_valid?(param)
      %w(housenumber street locality village town city).include?(param.downcase)
    end

    def code_param_is_valid?(param)
      (1..99999).include?(param.to_i)
    end

  end
end
