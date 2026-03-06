# === cvm_fund_lookup_service.rb
#
# @author Moisés Reis
# @added 03/06/2026
# @package *Meta*
# @description This service connects to the official **CVM** website to retrieve
#              public data about investment funds using a CNPJ.
# @category *Service*
#
# Usage:: - *[What]* A specialized crawler that navigates the CVM portal to find fund details.
#         - *[How]* It performs a GET request to find the fund and a POST to access hidden details.
#         - *[Why]* It automates data entry for fund names, administrators, and financial fees.
#
# Attributes:: - *@cnpj* @string - The cleaned numeric tax identification number of the fund.
#

require "nokogiri"
require "net/http"

class CvmFundLookupService
  # Explanation:: The base URLs for the CVM search form and the results page
  #               used to start the web scraping process.
  FORM_URL   = "https://cvmweb.cvm.gov.br/SWB/Sistemas/SCW/CPublica/CConsolFdo/FormBuscaParticFdo.aspx"
  RESULT_URL = "https://cvmweb.cvm.gov.br/SWB/Sistemas/SCW/CPublica/CConsolFdo/ResultBuscaParticFdo.aspx"

  # == call
  #
  # @author Moisés Reis
  # @category *Action* #
  # Action:: This class method initializes the service and cleans the input
  #          removing any non-numeric characters from the CNPJ string.
  #
  # Attributes:: - *cnpj* - the tax ID provided by the user or system.
  #
  def self.call(cnpj)
    new(cnpj.gsub(/\D/, "")).fetch
  rescue => e
    Rails.logger.error("[CVM] Erro crítico no lookup: #{e.message}")
    {}
  end

  # == initialize
  #
  # @author Moisés Reis
  # @category *Setup* #
  # Setup:: Stores the sanitized CNPJ in an instance variable to be
  #          used throughout the different stages of the web request.
  #
  # Attributes:: - *cnpj* - the numeric-only version of the tax ID.
  #
  def initialize(cnpj)
    @cnpj = cnpj
  end

  # == fetch
  #
  # @author Moisés Reis
  # @category *Process* #
  # Process:: Manages the multi-step navigation including session handling
  #            and form submission to reach the fund detail page.
  #
  def fetch
    # Explanation:: Formats the raw numbers into the standard XX.XXX.XXX/XXXX-XX
    #               pattern that the CVM search engine requires.
    cnpj_formatado = @cnpj.sub(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '\1.\2.\3/\4-\5')

    # Explanation:: Builds the specific web address for the search result including
    #               parameters for the fund type and administrator filters.
    result_uri = URI("#{RESULT_URL}?CNPJNome=#{URI.encode_www_form_component(cnpj_formatado)}&TpPartic=0&Adm=false&SemFrame=")

    # Explanation:: Initializes the network connection parameters like SSL
    #               and timeout limits for this specific request address.
    http = build_session(result_uri)

    req = Net::HTTP::Get.new(result_uri)
    req['User-Agent'] = 'Mozilla/5.0'
    res = http.request(req)
    return {} unless res.is_a?(Net::HTTPSuccess)

    # Explanation:: Converts the server response from the old ISO-8859-1 format
    #               to modern UTF-8 to correctly display accented characters.
    body = res.body.force_encoding("ISO-8859-1").encode("UTF-8", invalid: :replace, undef: :replace, replace: "")

    # Explanation:: Transforms the raw HTML text into a searchable object structure
    #               using the Nokogiri library for easy data extraction.
    doc = Nokogiri::HTML(body)

    fund_name = doc.at("#ddlFundos tr:first-child td:nth-child(2) a")&.text&.strip
    return {} if fund_name.blank?

    # Explanation:: Captures hidden security tokens from the ASP.NET form which are
    #               mandatory for the server to accept the next POST request.
    viewstate           = doc.at("#__VIEWSTATE")&.[]("value").to_s
    viewstate_generator = doc.at("#__VIEWSTATEGENERATOR")&.[]("value").to_s
    event_validation    = doc.at("#__EVENTVALIDATION")&.[]("value").to_s
    cookie              = res.get_fields('set-cookie')&.join('; ')

    # Explanation:: Prepares the data payload that simulates a user clicking on
    #               the first fund link in the results table.
    post_body = URI.encode_www_form(
      "__EVENTTARGET"        => "ddlFundos$_ctl0$lnkbtn1",
      "__EVENTARGUMENT"      => "",
      "__VIEWSTATE"          => viewstate,
      "__VIEWSTATEGENERATOR" => viewstate_generator,
      "__EVENTVALIDATION"    => event_validation
    )

    post_req = Net::HTTP::Post.new(result_uri)
    post_req['Content-Type'] = 'application/x-www-form-urlencoded'
    post_req['User-Agent']   = 'Mozilla/5.0'
    post_req['Cookie']       = cookie if cookie

    post_res = http.request(post_req, post_body)

    # Explanation:: Checks if the server redirected us to the final details page
    #               after the form was successfully submitted.
    detail_url = post_res['Location']
    return { fund_name: fund_name } if detail_url.blank?

    detail_url = "https://cvmweb.cvm.gov.br#{detail_url}" unless detail_url.start_with?("http")
    fetch_detail(detail_url, fund_name, cookie)
  end

  private

  # == fetch_detail
  #
  # @author Moisés Reis
  # @category *Network* #
  # Network:: Accesses the final URL where the fund details are located
  #            using the previously established session cookies.
  #
  # Attributes:: - *url* - the specific address of the fund details.
  #              - *fund_name* - the name already captured in the search.
  #              - *cookie* - the session token for authentication.
  #
  def fetch_detail(url, fund_name, cookie)
    uri  = URI(url)
    http = build_session(uri)

    req = Net::HTTP::Get.new(uri)
    req['User-Agent'] = 'Mozilla/5.0'
    req['Cookie']     = cookie if cookie

    res = http.request(req)
    return { fund_name: fund_name } unless res.is_a?(Net::HTTPSuccess)

    body = res.body.force_encoding("ISO-8859-1").encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    File.write(Rails.root.join("tmp/cvm_detail.html"), body)
    parse_detail(body, fund_name)
  end

  # == parse_detail
  #
  # @author Moisés Reis
  # @category *Extraction* #
  # Extraction:: Scans the final HTML page for specific ID tags to extract
  #              the administrator name and the financial fee values.
  #
  # Attributes:: - *html* - the source code of the detail page.
  #              - *fund_name* - the fund name to be included in the results.
  #
  def parse_detail(html, fund_name)
    doc = Nokogiri::HTML(html)

    # Explanation:: Targeted selectors for the administrator name and fees
    #               found in the specific table cells of the CVM portal.
    administrator_name = doc.at("#lbNmDenomSocialAdm")&.text&.strip
    administration_fee = parse_decimal(doc.at("#lbTxAdm")&.text)
    performance_fee    = parse_decimal(doc.at("#lbTxPerf")&.text)

    {
      fund_name:          fund_name,
      administrator_name: administrator_name,
      administration_fee: administration_fee,
      performance_fee:    performance_fee
    }.compact
  end

  # == build_session
  #
  # @author Moisés Reis
  # @category *Setup* #
  # Setup:: Configures the technical connection parameters like SSL security
  #          and maximum wait times for server responses.
  #
  # Attributes:: - *uri* - the destination address for the connection.
  #
  def build_session(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 15
    http
  end

  # == parse_decimal
  #
  # @author Moisés Reis
  # @category *Utility* #
  # Utility:: Converts text-based numbers with commas into a format that
  #            the database can understand as a valid decimal number.
  #
  # Attributes:: - *value* - the raw text value containing the percentage.
  #
  def parse_decimal(value)
    return nil if value.blank?

    # Explanation:: Removes currency symbols or spaces and replaces commas with
    #               dots to follow the standard computer calculation format.
    value.gsub(/[^\d,]/, "").gsub(",", ".").to_d
  rescue
    nil
  end
end