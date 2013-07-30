
require 'nokogiri'

module SterlingApi

  class BackgroundCheck
    extend XmlHelper

    def self.all_ids(mode)
      mode.to_s =~ /prod/ ? [25212, 25213, 25214, 25750, 25751, 25752, 25753, 25911] : [19432, 19439, 19440, 19442, 19443, 19444, 19445, 19437]
    end

    def self.mvr_ids(mode)
      mode.to_s =~ /prod/ ? [25214, 25750] : [19440, 19442]
    end

    # 
    # PRI-FAM:
    # PRI-FFM:
    # PRI-FIM:
    # PRINCRF:
    # PRINCRP:
    #   PersonalData/PersonName
    #   PersonalData/PostalAddress
    # 
    # SSNV:
    #   PersonalData/DemographicDetail
    # 
    # MVR:
    #   PersonalData/Licenses
    # 
    
    
    # combos
    #  19432 = Package 1 = PRI-FIM, PRINCRF, PRINCRP, SSNV
    #  19439 = Package 2 = PRI-FAM, PRINCRP, SSNV
    #  19440 = Package 3 = MVR, PRINCRP, SSNV
    #
    # ala carte
    #  19442 = Package 5 = MVR only
    #  19443 = Package 6 = PRINCRP
    #  19444 = Package 7 = PRI-FFM, SSNV
    #  19445 = Package 9 = PRI-FFM
    #  19437 = Package 14 = PRI-FAM
    #
    #
    #  2011-02-22:
    #  Package 1 can logically be ordered with 5,9 & 14
    #  Package 2 can logically be ordered with 5 & 9
    #  Package 3 can logically be ordered with 9 & 14
    #  Any combination of 5,6,7,9 & 14 could be ordered.
    #  
    #
    def self.for_package(package_id, options)
      package_id = package_id.to_i
      
      background_check = self.new(options.merge(:package_id => package_id))

      background_check.add_ssnv # required for one-step orders

      background_check.add_name_and_address if all_ids(options[:mode]).include?(package_id)
      background_check.add_mvr              if mvr_ids(options[:mode]).include?(package_id)
      
      background_check
    end

    def initialize(options={})
      @options = options
      @xml = create_root
      self
    end

    #  <BackgroundCheck
    #      userId="#{@order_as_user_id}"
    #      account="#{@account}"
    #      password="#{@password}">
    #    <BackgroundSearchPackage>
    #      <PersonalData>
    #        <ContactMethod>
    #          <InternetEmailAddress></InternetEmailAddress>
    #        </ContactMethod>
    #      </PersonalData>
    #      <Screenings>
    #        <PackageID>#{@package_id}</PackageID>
    #        <UserArea>
    #          <UserAreaContent>
    #            <PositionTitle>#{@position_applied_for}</PositionTitle>
    #          </UserAreaContent>
    #        </UserArea>
    #        (if non-MVR)
    #          <Screening type="abuse">
    #        (if MVR)
    #          <Screening type="license", qualifer="mvPersonal">
    #      </Screenings>
    #    </BackgroundSearchPackage>
    #    <UserArea>
    #      <UserAreaContent>
    #        <OnlineAddress>
    #          <InternetWebAddress>#{AppSettings[:sterling_return_url]}</InternetWebAddress>
    #        </OnlineAddress>
    #        <ReturnOrderNumber>Y</ReturnOrderNumber>
    #        <ResultStatusReturn>
    #          <RedStatusReturn>Ineligble</RedStatusReturn>
    #          <YellowStatusReturn>Decisional</YellowStatusReturn>
    #          <GreenStatusReturn>Eligible</GreenStatusReturn>
    #        </ResultStatusReturn>
    #      </UserAreaContent>
    #    </UserArea>
    #  </BackgroundCheck>
    # 
    def create_root
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.BackgroundCheck(
          :userId => @options[:order_as_user_id],
          :account => @options[:account],
          :password => @options[:password]
        ){
          xml.BackgroundSearchPackage{
            xml.PersonalData{
              xml.ContactMethod{
                xml.InternetEmailAddress @options[:contact_email]
              }
            }
            xml.Screenings{
              xml.PackageID @options[:package_id]
              xml.UserArea {
                xml.userAreaContent{
                  xml.PositionTitle @options[:position_applied_for]
                }
              }
              if self.class.mvr_ids(@options[:mode]).include?(@options[:package_id])
                xml.Screening(:type =>  "license", :qualifier => "mvPersonal")
              else
                xml.Screening(:type =>  "abuse")
              end
            }
          }
          xml.UserArea{
            xml.UserAreaContent{
              xml.OnlineAddress{
                xml.InternetWebAddress AppSettings[:sterling_return_url]
              }
              xml.ReturnOrderNumber "Y"
              xml.ResultStatusReturn {
                xml.RedStatusReturn "Ineligible"
                xml.YellowStatusReturn "Decisional"
                xml.GreenStatusReturn "Eligible"
              }
            }
          }
        }
      end

      builder.to_xml
    end

    # Contains 0*
    # //BackgroundCheck/BackgroundSearchPackage/Screenings/Screening/SearchLicense
    #
    # options should contain:
    #   licenses:  an array of license info hashes
    #
    # license info hash:
    #   :license_number  AN 1..20
    #   :license_region  2 char State/Region
    #
    def add_mvr
      builder = Nokogiri::XML::Builder.with(screening_node) do |xml|
        @options[:licenses].each do |hash|
          # xml.SearchLicense(:validFrom => ymd(hash[:valid_from]), :validTo => ymd(hash[:valid_to])) {
          xml.Region hash[:license_region] # State
          xml.SearchLicense {
            xml.License {
              xml.LicenseNumber(hash[:license_number])
              xml.LicenseName 'mvr'
              xml.LicenseDescription 'mvr'
              xml.LicensingAgency
            }
          }
        end
      end

      @xml = builder.to_xml
    end

    # 
    # expects an array of :person_names in @options
    # expects an array of :postal_addresses in @options
    #
    #  <PersonName type="subject|alias">
    #    <GivenName>Kevin</GivenName>
    #    <MiddleName>Fred</MiddleName>
    #    <FamilyName>Test</FamilyName>
    #  </PersonName>
    #  <PostalAddress type="current|prior" validFrom="2009-01-01">
    #    <Municipality>Madison</Municipality>
    #    <Region>WI</Region>
    #    <PostalCode>53711</PostalCode>
    #    <CountryCode>US</CountryCode>
    #    <DeliveryAddress>
    #      <AddressLine>1234 Main Rd</AddressLine>
    #    </DeliveryAddress>
    #  </PostalAddress>
    def add_name_and_address
      builder = Nokogiri::XML::Builder.with(personal_data_node) do |xml|
        @options[:person_names].each do |hash|
          xml.PersonName(:type => hash[:type]){
            xml.GivenName hash[:first_name]
            xml.MiddleName hash[:middle_name]
            xml.FamilyName hash[:last_name]
          }
        end if @options[:person_names]

        @options[:postal_addresses].each do |hash|
          xml.PostalAddress(:type => hash[:type], :validFrom => ymd(hash[:valid_from]), :validTo => ymd(hash[:valid_to])){
            xml.Municipality hash[:municipality]
            xml.Region hash[:region]
            xml.PostalCode hash[:postal_code]
            xml.CountryCode hash[:country_code]
            xml.DeliveryAddress{
              xml.AddressLine hash[:address1]
              xml.AddressLine(hash[:address2]) if hash[:address2].present?
            }
          }
        end if @options[:postal_addresses]
      end

      @xml = builder.to_xml
    end

    #  <DemographicDetail>
    #    <GovernmentId issuingAuthority="SSN">123456789</GovernmentId>
    #    <DateOfBirth>1950-01-01</DateOfBirth>
    #  </DemographicDetail>
    #
    def add_ssnv
      builder = Nokogiri::XML::Builder.with(personal_data_node) do |xml|
        xml.DemographicDetail{
          xml.GovernmentId(@options[:ssn], :issuingAuthority => 'SSN')
          xml.DateOfBirth(ymd(@options[:date_of_birth]))
        }
      end

      @xml = builder.to_xml
    end

    def to_xml
      self.class.xml_rpc_wrapper(@xml)
    end

    protected

    def doc
      Nokogiri::XML(@xml)
    end

    def personal_data_node
      doc.at('//BackgroundCheck/BackgroundSearchPackage/PersonalData')
    end

    def screening_node
      doc.at('//BackgroundCheck/BackgroundSearchPackage/Screenings/Screening')
    end

    # expects a Time or DateTime
    def ymd(date)
      return date if date.is_a?(String)
      date.strftime("%Y-%m-%d") if date
    end

    
    module XML

      SAMPLE_ORDER_RESPONSE = %Q{<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope
    xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:cp="http://www.cpscreen.com/schemas"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soapenv:Body>
    <BackgroundReports xmlns="http://www.cpscreen.com/schemas">
      <BackgroundReportPackage type="report">
        <ProviderReferenceId>WPS-6266154</ProviderReferenceId>
        <PackageInformation>
          <ClientReferences>
            <ClientReference>Youth123456</ClientReference>
            <ClientReference>CN=Youth Tester/O=Youth</ClientReference>
          </ClientReferences>
          <Quotebacks>
            <Quoteback name="Youth-83SQ7J"/>
          </Quotebacks>
        </PackageInformation>
        <PersonalData>
          <PersonName type="subject">
            <GivenName>Test</GivenName>
            <FamilyName>Youth</FamilyName>
          </PersonName>
          <DemographicDetail>
            <GovernmentId issuingAuthority="SSN">123456789</GovernmentId>
            <DateOfBirth/>
            <Gender>F</Gender>
          </DemographicDetail>
        </PersonalData>
        <ScreeningStatus>
          <OrderStatus>InProgress</OrderStatus>
        </ScreeningStatus>
        <ScreeningResults mediaType="html">
          <InternetWebAddress>https://screentest.lexisnexis.com/pub/l/login/userLogin.do?referer=https://screentest.lexisnexis.com/pub/l/jsp/menu/orderViewingMenuFrameSet.jsp?key=123|ABCDEFG</InternetWebAddress>
        </ScreeningResults>
      </BackgroundReportPackage>
    </BackgroundReports>
  </soapenv:Body>
</soapenv:Envelope>
      }

      SAMPLE_USER_LOCKED_RESPONSE = %q[<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope
    xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:cp="http://www.cpscreen.com/schemas"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <soapenv:Body>
    <BackgroundReports xmlns="http://www.cpscreen.com/schemas">
      <BackgroundReportPackage type="errors">
        <ErrorReport>
          <ErrorCode>210</ErrorCode>
          <ErrorDescription>User is locked</ErrorDescription>
        </ErrorReport>
      </BackgroundReportPackage>
    </BackgroundReports>
  </soapenv:Body>
</soapenv:Envelope>
      ]
  
    end # module XML

  end # class BackgroundCheck

end
