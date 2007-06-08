class ChatGenerator < Rails::Generator::NamedBase
  def initialize(runtime_args, runtime_options)
    base_name = runtime_args.shift || 'chat'
    runtime_args.unshift(base_name)
    super
  end

  def manifest
    controller_class = "#{class_name}Controller"
    controller_file = "#{file_name}_controller"
    record do |m|
      m.class_collisions(controller_class, "#{controller_class}Test")
      m.class_collisions(class_name, "#{class_name}Test")
      
      m.directory File.join('app/controllers', class_path)
      m.directory File.join('test/functional', class_path)
      m.directory File.join('app/views', class_path, file_name)
      m.directory File.join('app/models', class_path)
      m.directory File.join('test/unit', class_path)

      m.template 'controller.rb',
        File.join('app/controllers', class_path, "#{controller_file}.rb")
      m.template 'functional_test.rb',
        File.join('test/functional', class_path, "#{controller_file}_test.rb")

      m.template 'helper.rb',
        File.join('app/helpers', class_path, "#{file_name}_helper.rb")

      m.template 'layout.rhtml',
        File.join('app/views', class_path, "layouts/#{file_name}.rhtml")
      m.template 'index.rhtml',
        File.join('app/views', class_path, "#{file_name}/index.rhtml")
      m.template 'show.rhtml',
        File.join('app/views', class_path, "#{file_name}/show.rhtml")

      m.template 'model.rb',
        File.join('app/models', class_path, "#{file_name}.rb")
      m.template 'unit_test.rb',
        File.join('test/unit', class_path, "#{file_name}_test.rb")

      m.migration_template 'migration.rb', 'db/migrate',
        :migration_file_name => "create_#{file_name.pluralize}"
    end
  end
end
