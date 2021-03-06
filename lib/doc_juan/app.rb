require 'sinatra/base'
require_relative 'auth'

module DocJuan
  class App < Sinatra::Base

    enable :logging

    before '/render*' do
      halt 401, 'Invalid key' unless DocJuan::Auth.valid_request?(request)
    end

    # empty page on index
    get '/' do
    end

    error DocJuan::CouldNotGenerateFileError do
      if defined? Airbrake
        error = request.env['sinatra.error']
        Airbrake.notify(
          error_class: error.class.to_s,
          error_message: "#{error.class}: #{error.message}",
          parameters: request.params
        )
      end
      halt 500, 'Could not generate file'
    end

    # render a html page to a document
    get '/render' do
      renderer_class = DocJuan.renderer params[:format]
      renderer = renderer_class.new params[:url], params[:filename], params[:options]
      result = renderer.generate

      headers['Content-Type'] = result.mime_type
      headers['Content-Disposition'] = "inline; filename=\"#{result.filename}\""
      headers['Cache-Control'] = 'public,max-age=2592000'
      headers['X-Accel-Redirect'] = result.path
    end

    get '/robots.txt' do
      headers['Content-Type'] = "text/plain"

      "User-agent: *\nDisallow: /"
    end
  end
end
