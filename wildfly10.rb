class Wildfly10 < Formula
  desc "Managed Java EE application server/runtime"
  homepage "http://wildfly.org/"
  url "https://download.jboss.org/wildfly/10.1.0.Final/wildfly-10.1.0.Final.tar.gz"
  sha256 "80781609be387045273f974662dadf7f64ad43ee93395871429bc6b7786ec8bc"

  bottle :unneeded

  depends_on :java => "1.8+"

  def java8u51_home
    "/Library/Java/JavaVirtualMachines/jdk1.8.0_51.jdk/Contents/Home"
  end

  def self.server_config
    "standalone-full.xml"
  end

  def install
    rm_f Dir["bin/*.bat"]
    rm_f Dir["bin/*.ps1"]
    libexec.install Dir["*"]
    mkdir_p libexec/"standalone"/"log"

    {
      "add-user.sh" => "wf10-add-user",
      "jboss-cli.sh" => "wf10-jboss-cli",
      "standalone.sh" => "wf10-standalone",
    }.each do |script, stub|
      (bin/stub).write <<-EOS.undent
        #!/bin/sh
        export JAVA_HOME="#{java8u51_home}"
        export JBOSS_HOME="#{opt_libexec}"
        export WILDFLY_HOME="#{opt_libexec}"
        exec "#{opt_libexec}/bin/#{script}" "$@"
      EOS
    end
  end

  def caveats; <<-EOS.undent
    The home of WildFly #{version} is:
      #{opt_libexec}
    You may want to add the following to your .bash_profile:
      export JBOSS_HOME=#{opt_libexec}
    EOS
  end

  plist_options :manual => "wf10-standalone --server-config=#{server_config}"

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>KeepAlive</key>
      <dict>
        <key>SuccessfulExit</key>
        <false/>
        <key>Crashed</key>
        <true/>
      </dict>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_libexec}/bin/standalone.sh</string>
        <string>--server-config=#{self.class.server_config}</string>
      </array>
      <key>EnvironmentVariables</key>
      <dict>
        <key>JAVA_HOME</key>
        <string>#{java8u51_home}</string>
        <key>JBOSS_HOME</key>
        <string>#{opt_libexec}</string>
        <key>WILDFLY_HOME</key>
        <string>#{opt_libexec}</string>
      </dict>
    </dict>
    </plist>
    EOS
  end

  test do
    ENV["JBOSS_HOME"] = opt_libexec
    system "#{opt_libexec}/bin/standalone.sh --version | grep #{version}"
  end
end
