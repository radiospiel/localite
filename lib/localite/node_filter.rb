module Localite::NodeFilter
  module ControllerFilter
    #
    # set up localite for this action.
    def self.filter(controller, &block)
      return unless controller.response.headers["Content-Type"] =~ /text\/html/
      controller.response.body = filter_lang_nodes(controller.response.body)
    rescue
      if Rails.env.development?
        controller.response.body = "Caught exception: " + CGI::escapeHTML($!.inspect) 
      end
      raise
    end

    def self.filter_lang_nodes(body)
      doc = Nokogiri.XML "<filter-outer-span xmlns:fb='http://facebook.com/'>#{body}</filter-outer-span>"

      doc.css("[lang]").each do |node|
        if Localite.locale.to_s != node["lang"]
          node.remove
          next
        end

        #
        # we have a node with content specific for the current locale,
        # i.e. a node to keep. If we find a base locale sibling (i.e. 
        # with identical attributes but no "lang" attribute) prior 
        # this node we have to remove that.
        next unless base = base_node(node)
        base.remove 
      end

      doc.css("filter-outer-span").inner_html
    end
    
    def self.base_node(node)
      previous = node
      while (previous = previous.previous) && previous.name == "text" do
        :void
      end

      return previous if base_node?(node, previous)
    end
    
    def self.base_node?(me, other_node)
      return false if !other_node
      return false if me.name != other_node.name
      return false if other_node.attributes.key?("lang")
      return false if me.attributes.length != other_node.attributes.length + 1

      # do we have a mismatching attribute?
      other_node.attributes.each { |k,v| 
        return false if me.attributes[k] != v 
      }

      true
    end
  end

  def self.included(klass)
    klass.send :around_filter, ControllerFilter
  end
end
