module Pakyow
  module Console
    class SitemapXML
      def initialize
        @urls = []
      end

      def url(location: nil, frequency: nil, modified: nil)
        @urls << {
          location: location,
          frequency: frequency,
          modified: modified
        }
      end

      def delete_location(location)
        @urls.delete_if { |u| u[:location] == location }
      end

      def to_s
        doc = Oga::XML::Document.new(type: :xml)

        urlset = Oga::XML::Element.new(name: :urlset)
        urlset.set('xmlns', 'http://www.sitemaps.org/schemas/sitemap/0.9')
        urlset.set('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance')
        urlset.set('xsi:schemaLocation', 'http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd')

        @urls.each do |url|
          xml_url = Oga::XML::Element.new(name: :url)

          if url[:location]
            xml_loc = Oga::XML::Element.new(name: :loc)
            xml_loc.inner_text = url[:location]
            xml_url.children << xml_loc
          end

          if url[:frequency]
            xml_changefreq = Oga::XML::Element.new(name: :changefreq)
            xml_changefreq.inner_text = url[:frequency]
            xml_url.children << xml_changefreq
          end

          if url[:modified]
            xml_lastmod = Oga::XML::Element.new(name: :lastmod)
            xml_lastmod.inner_text = url[:modified]
            xml_url.children << xml_lastmod
          end

          urlset.children << xml_url
        end

        doc.children << urlset
        doc.to_xml
      end
    end
  end
end
