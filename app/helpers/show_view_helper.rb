module ShowViewHelper

  def show_config
    ShowViewBuilder.new(self)
  end

  class ShowViewBuilder
    attr_reader :context

    def initialize(context)
      @context = context
      @config = {
        page: {},
        sections: []
      }
    end

    def page(title:, description:, view: "show")
      @config[:page] = {
        title: title,
        description: description,
        view: view
      }
      self
    end

    def section(**options, &block)
      section_builder = SectionBuilder.new(context, options)
      section_builder.instance_eval(&block) if block_given?
      @config[:sections] << section_builder.build
      self
    end

    def build
      @config
    end
  end

  class SectionBuilder
    def initialize(context, options)
      @context = context
      @config = {
        title: options[:title],
        desc: options[:desc],
        columns: options[:columns] || 1,
        has_action: options[:has_action] || false,
        button_route: options[:button_route],
        button_name: options[:button_name],
        button_icon: options[:button_icon],
        items: []
      }
    end

    def card(**options, &block)
      @config[:items] << {
        type: :card,
        title: options[:title],
        icon_name: options[:icon_name],
        data: options[:data],
        data_icon_name: options[:data_icon_name],
        status: options[:status] || :default,
        is_outline: options[:is_outline] != false,
        content: block ? @context.capture(&block) : nil
      }
    end

    def summary_card(**options, &block)
      @config[:items] << {
        type: :summary_card,
        title: options[:title],
        icon: options[:icon],
        data: options[:data],
        data_icon: options[:data_icon],
        is_success: options[:is_success],
        is_danger: options[:is_danger],
        is_warning: options[:is_warning],
        content: block ? @context.capture(&block) : nil
      }
    end

    def chart(**options, &block)
      @config[:items] << {
        type: :chart,
        title: options[:title],
        data_source: options[:data_source],
        chart_type: options[:chart_type] || :line,
        chart_options: options[:chart_options] || {},
        content: block ? @context.capture(&block) : nil
      }
    end

    def table(**options)
      @config[:items] << {
        type: :table,
        models: options[:models],
        columns_header: options[:columns_header],
        columns_icons: options[:columns_icons],
        columns_body: options[:columns_body],
        empty_message: options[:empty_message] || "N/A"
      }
    end

    def info_card(**options)
      @config[:items] << {
        type: :info_card,
        title: options[:title],
        subtitle: options[:subtitle],
        main_value: options[:main_value],
        sub_value: options[:sub_value],
        icon_name: options[:icon_name],
        main_color: options[:main_color]
      }
    end

    def list(**options, &block)
      list_items = []
      if block_given?
        list_builder = ListBuilder.new(@context)
        list_builder.instance_eval(&block)
        list_items = list_builder.items
      end

      @config[:items] << {
        type: :list,
        items: list_items,
        show_all_link: options[:show_all_link],
        empty_message: options[:empty_message] || "N/A"
      }
    end

    def separator
      @config[:items] << {
        type: :separator
      }
    end

    def subsection(**options, &block)
      subsection_builder = SectionBuilder.new(@context, options)
      subsection_builder.instance_eval(&block) if block_given?
      @config[:items] << {
        type: :subsection,
        config: subsection_builder.build
      }
    end

    def build
      @config
    end
  end

  class ListBuilder
    attr_reader :items

    def initialize(context)
      @context = context
      @items = []
    end

    def item(**options)
      @items << options
    end
  end
end