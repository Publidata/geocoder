require 'geocoder/results/base'

module Geocoder::Result
  class BanDataGouvFr < Base

    #### BASE METHODS ####

    def self.response_attributes
      %w[limit attribution version licence type features]
    end

    response_attributes.each do |a|
      unless method_defined?(a)
        define_method a do
          @data[a]
        end
      end
    end

    #### BEST RESULT ####

    def result
      features[0] if features.any?
    end

    #### GEOMETRY ####

    def geometry
      result['geometry'] if result
    end

    def precision
      geometry['type'] if geometry
    end

    def coordinates
      coords = geometry["coordinates"]
      return [coords[1].to_f, coords[0].to_f]
      #['lat', 'lng'].map{ |i| geometry['location'][i] }
    end

    #### PROPERTIES ####

    # List of available properties:
    #
    #   id : identifiant de l'adresse (non stable: actuellement identifiant IGN)
    #   type : type de résultat trouvé
    #   housenumber : numéro "à la plaque"
    #   street : position "à la voie", placé approximativement au centre de celle-ci
    #   place : lieu-dit
    #   village : numéro "à la commune" dans un village
    #   town : numéro "à la commune" dans une ville moyenne
    #   city : numéro "à la commune" dans une grande ville
    #   score : valeur de 0 à 1 indiquant la pertinence du résultat
    #   housenumber : numéro avec indice de répétition éventuel (bis, ter, A, B)
    #   name : numéro éventuel et nom de voie ou lieu dit
    #   postcode : code postal
    #   citycode : code INSEE de la commune
    #   city : nom de la commune
    #   context : n° de département, nom de département et de région
    #   label : libellé complet de l'adresse
    #
    #   For up to date doc (in french only) : https://adresse.data.gouv.fr/api/
    #
    def properties
      result['properties'] if result
    end

    def score
      properties['score']
    end

    def address_id
      properties['id']
    end

    # Types
    #
    #   housenumber
    #   street
    #   city
    #   town
    #   village
    #   locality
    #
    def result_type
      properties['type']
    end

    def label
      properties['label']
    end

    def address(format = :full)
      "#{label}, #{country}"
    end

    def street_number
      properties['housenumber']
    end

    def street_name
      properties['street']
    end

    def street_address
      properties['name']
    end

    def city_name
      properties['city']
    end

    def city_code
      properties['citycode']
    end

    def postal_code
      properties['postalcode']
    end

    def context
      properties['context'].split(/,/).map(&:strip)
    end

    def department_code
      context[0] if context.length > 0
    end

    # Monkey logic to handle fact Paris is both a city and a department
    # in Île-de-France region
    def department_name
      if context.length > 1
        if context[1] == "Île-de-France"
          "Paris"
        else
          context[1]
        end
      end
    end

    def region_name
      if context.length == 2 && context[1] == "Île-de-France"
        context[1]
      elsif context.length > 2
        context[2]
      end
    end

    def country
      "France"
    end

    # Country code types
    #    FR : France
    #    GF : Guyane Française
    #    RE : Réunion
    #    NC : Nouvelle-Calédonie
    #    GP : Guadeloupe
    #    MQ : Martinique
    #    MU : Maurice
    #    PF : Polynésie française
    #
    # to refacto to handle different country codes
    def country_code
      "FR"
    end

    #### ALIAS METHODS ####

    alias_method :city, :city_name
    alias_method :state, :department_name

    #### CITIES' METHODS ####

    def population
      (properties['population'].to_f * 1000).to_i if city?(result_type)
    end

    def administrative_weight
      properties['adm_weight'].to_i if city?(result_type)
    end

    private

    def city?(result_type)
      %w(village town city).include?(result_type)
    end

  end
end
