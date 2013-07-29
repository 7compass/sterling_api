$: << File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'sterling_api/xml_helper'
require 'sterling_api/background_check'
require 'sterling_api/password_change'
require 'sterling_api/remote_actions'

module SterlingApi

  URLS = {
    :test => {
      :wsdl_background_checks => {
        :name => 'WSDL - Back Ground Checks',
        :description => 'URL for background screening web services WSDL',
        :url => 'https://deuce.tandemselect.com:9000/wh_soap_listener.cgi'
      },
      :order_one_step => {
        :name => 'New Requests URL - Customer Test (One-Step)',
        :description => 'URL for web service CreateOrder',
        :url => 'https://deuce.tandemselect.com:9000/wh_soap_listener.cgi'
      },
      :order_two_step => {
        :name => 'New Requests URL - Customer Test (Two-Step)',
        :description => 'URL for web service CreateOrder',
        :url => 'https://deuce.tandemselect.com:9000/wh_soap_listener.cgi'
      },
      :provider_website => {
        :name => 'Provider Website URL - Test',
        :description => 'CPScreen.com URL',
        :url => 'https://deuce.tandemselect.com:9000/wh_soap_listener.cgi'
      },
      :response_post => {
        :name => 'Response URL - Customer Test',
        :description => 'URL ChoicePoint uses to post results to ATS',
        :url => ''
      },
      :wsdl_admin => {
        :name => 'WSDL - Admin',
        :description => 'URL for admin web services WSDL',
        :url => 'https://deuce.tandemselect.com:9000/wh_soap_listener.cgi'
      },
      :password_change => {
        :name => 'Password Change Requests URL - Test',
        :description => 'URL for web service ChangePasswords, GetPackages',
        :url => 'https://deuce.tandemselect.com:9000/wh_soap_listener.cgi'
      },
    },

    :prod => {
      :wsdl_background_checks => {
        :name => 'WSDL - Back Ground Checks',
        :description => 'URL for background screening web services WSDL',
        :url => 'https://orders.tandemselect.com:444/wh_soap_listener.cgi'
      },
      :order_one_step => {
        :name => 'New Requests URL - Production (One-Step)',
        :description => 'URL for web service CreateOrder',
        :url => 'https://orders.tandemselect.com:444/wh_soap_listener.cgi'
      },
      :order_two_step => {
        :name => 'New Requests URL - Production (Two-Step)',
        :description => 'URL for web service CreateOrder',
        :url => 'https://orders.tandemselect.com:444/wh_soap_listener.cgi'
      },
      :provider_website => {
        :name => 'Provider Website URL - Production',
        :description => 'CPScreen.com URL',
        :url => 'https://orders.tandemselect.com:444/wh_soap_listener.cgi'
      },
      :response_post => {
        :name => 'Response URL - Production',
        :description => 'URL ChoicePoint uses to post results to ATS',
        :url => ''
      },
      :wsdl_admin => {
        :name => 'WSDL - Admin',
        :description => 'URL for admin web services WSDL',
        :url => 'https://orders.tandemselect.com:444/wh_soap_listener.cgi'
      },
      :password_change => {
        :name => 'Password Change Requests URL - Production',
        :description => 'URL for web service ChangePasswords, GetPackages',
        :url => 'https://orders.tandemselect.com:444/wh_soap_listener.cgi'
      },
    }
  }


  class Api

    # mode: prod[uction] or test
    def initialize(mode)
      @mode = mode
      # test system password is 'Password2' until changed
      self
    end

    def mode
      @mode.to_s =~ /prod/i ? :prod : :test
    end

    def order(background_check)
      req = SterlingApi::RemoteActions::Request.new(
        :url => url(:order_one_step),
        :body => background_check.to_xml
      )
      req.send_request
    end

    def password_change_request(password_change)
      req = SterlingApi::RemoteActions::Request.new(
        :url => url(:password_change),
        :body => password_change.to_xml
      )
      req.send_request
    end

    def url(type)
      SterlingApi::URLS[mode][type][:url]
    end

  end # class Api


end
