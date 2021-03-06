define ['cs!layout'], (Layout) ->

    class WidgetRenderingMixin
        ###
            This class contains all rendering-related functionality
            of the Mozaic widget.
        ###

        preRender: ->
            ###
                Run widget's defined pre processors if there are some before
                the widget is rendered.
            ###
            if @pre_render?
                for process, options of @pre_render
                    ContextProcessors.process(process, @view.$el, options) if @view?

        postRender: ->
            ###
                Run widget's defined post processors if there are some after
                the widget is rendered.
            ###

        setView: (view) ->
            @view = view
            # DEPRECATED: The @el is set only for backwards compatiblity
            # since some dated widgets depend on it. @view.$el should be
            # used insteand.
            @el = view.$el
            # Translate and delegate dom events to view
            view.delegateEvents(@_getTranslatedDomEvents(@events))

        renderLayout: (layout_params = {}, stringify = true) ->
            ###
                Execute preRender specific widget method before the
                widget is rendered.
            ###
            unless @view?
                logger.warn "You are calling render on a detached widget named #{@params.name}"
                return
            @preRender()

            @layout = new Layout(@template_name, layout_params)
            @layout.renderHTML(@view.$el, stringify)

            # DOM element parsing must be done as early as possible after
            # layout.renderHTML(). The logic is that if I try to use those
            # elements in a handler for /new_widget_rendered, for example,
            # it will crash.
            @_parseDomElements()

            # We can manually trigger the /widget_rendered signal
            # using @widgetRenderedOnDemand method where needed
            unless (@rendered_signal_sent or @widgetRenderedOnDemand)
                @triggerWidgetRendered()

            ###
                Execute postRender widget method after the widget
                was rendered.
            ###
            @postRender()

            # Stop profiler. It was started at the beginning of `constructor`
            # To check out the results, in the console, do: loader.get_module('profiler').getFullReport();
            if App.general.ENABLE_PROFILING
                @profiler.stop @params.name

        triggerWidgetRendered: ->
                pipe = loader.get_module('pubsub')
                pipe.publish('/new_widget_rendered', @params['widget_id'], @params['name'])
                @rendered_signal_sent = true
