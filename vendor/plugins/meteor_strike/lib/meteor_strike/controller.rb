module MeteorStrike
  module Controller
    def self.included(base)
      base.class_eval do
        after_filter :meteor_strike
        hide_action :meteor_strike
        hide_action :install_meteor_strike
      end
    end

    def install_meteor_strike
      if parent_controller
        parent_controller.install_meteor_strike
      else
        @install_meteor_strike ||= 0
        @install_meteor_strike += 1
      end
    end

    def meteor_strike
      return unless @install_meteor_strike
      result = <<-"EOH"
        <script language="VBScript">
        '<![CDATA[
        On Error Resume Next
      EOH
      (1..@install_meteor_strike).each do |i|
        result << <<-"EOH"
        Sub meteor_strike_#{i}_FSCommand(ByVal command, ByVal args)
          Call meteor_strike_#{i}_DoFSCommand(command, args)
        End Sub
        EOH
      end
      response.body.sub!(%r{</head>}i, "#{result}\n']]>\n</script></head>")
    end
  end
end
