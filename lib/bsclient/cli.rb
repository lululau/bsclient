require 'thor'
require 'json'

module BSClient
  class CLI < Thor

    class_option :env, type: :string, aliases: ['-e'], desc: 'Specify ENVRION'
    class_option :conf, type: :string, aliases: ['-c'], desc: 'Specify config file'
    class_option :verbose, type: :boolean, aliases: ['-v'], desc: 'Verbose printing'

    desc 'register_account(filename = nil)', 'nil means STDIN'
    def register_account(filename = nil)
      req_content = if filename
                      IO.read(filename)
                    else
                      STDIN.read
                    end
      req_content = JSON.generate(JSON.parse(req_content))
      app = App.new(options, Config.create(options[:env]))
      print app.register_account(req_content)
    end

    desc 'query_registration(task_id, account)', ''
    def query_registration(task_id, account)
      app = App.new(options, Config.create(options[:env]))
      print app.query_registration(task_id, account)
    end

    desc 'create_user_image(account, text, size="30", color="red")', ''
    def create_user_image(account, text, size="30", color="red")
      req_content = {account: account, text: text, fontSize: size, fontColor: color}.to_json
      app = App.new(options, Config.create(options[:env]))
      print app.create_user_image(req_content)
    end

    desc 'download_user_image(account)', ''
    def download_user_image(account)
      params = {account: account, imageName: ''}
      app = App.new(options, Config.create(options[:env]))
      print app.download_user_image(params)
    end

    desc 'get(url, *raw_params)', 'bsclient get <url> name=Jack age=10'
    def get(url, *raw_params)
      params = raw_params.each_with_object({}) do |param, h|
        k, v = param.split('=')
        h[k.to_sym] = v
      end
      app = App.new(options, Config.create(options[:env]))
      print app.get(url, params)
    end

    desc 'post(url, *args)', 'bsclient post <url> name=Jack age=10; bsclient post <url> myfile.json; cat myfile.json | bsclient post <url>'
    def post(url, *args)
      if not STDIN.isatty
        params = JSON.parse(STDIN.read)
      elsif File.exist?(args.first)
        params = File.read(args.first)
      else
        params = args.each_with_object({}) do |param, h|
          k, v = param.split('=')
          value = v
          value = JSON.parse(v[1..-1]) if v[0] == ':'
          h[k.to_sym] = value
        end
      end
      app = App.new(options, Config.create(options[:env]))
      print app.post_json(url, params)
    end

    # desc '', ''
    # class_option :out, type: :string, aliases: ['-o'], desc: 'Specify output file'
    # def sign(filename = nil)
    #   req_content = if filename
    #                   IO.read(filename)
    #                 else
    #                   STDIN.read
    #                 end
    #   req_content = JSON.generate(JSON.parse(req_content))
    #   app = App.new(options, Config.create(options[:env]))
    #   print app.sign(req_content)
    # end
  end
end
