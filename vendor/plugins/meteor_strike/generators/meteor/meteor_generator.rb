class MeteorGenerator < Rails::Generator::NamedBase
  def initialize(runtime_args, runtime_options)
    base_name = 'meteor'
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

      m.file 'view.rhtml',
        File.join('app/views', class_path, "#{file_name}/strike.rhtml")

      m.template 'model.rb',
        File.join('app/models', class_path, "#{file_name}.rb")
      m.template 'unit_test.rb',
        File.join('test/unit', class_path, "#{file_name}_test.rb")

      m.migration_template 'migration.rb',
        File.join('db/migrate', class_path),
        :migration_file_name => 'create_meteors'
    end
  end
end
