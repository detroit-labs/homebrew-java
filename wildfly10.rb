class Wildfly10 < Formula
  desc "Managed Java EE application server/runtime."
  homepage "http://wildfly.org/"
  url "https://download.jboss.org/wildfly/10.0.0.Final/wildfly-10.0.0.Final.tar.gz"
  sha256 "e00c4e4852add7ac09693e7600c91be40fa5f2791d0b232e768c00b2cb20a84b"

  bottle :unneeded

  def install
    rm_f Dir["bin/*.bat"]
    rm_f Dir["bin/*.ps1"]
    libexec.install Dir["*"]
    mkdir_p libexec/"standalone"/"log"
  end

  plist_options :startup => false

  def plist; <<-EOS.undent
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>KeepAlive</key>
      <true/>
      <key>ProgramArguments</key>
      <array>
        <string>#{opt_libexec}/bin/standalone.sh</string>
      </array>
      <key>EnvironmentVariables</key>
      <dict>
        <key>JBOSS_HOME</key>
        <string>#{opt_libexec}</string>
      </dict>
    </dict>
    </plist>
    EOS
  end

  def caveats; <<-EOS.undent
    The home of WildFly #{version} is:
      #{opt_libexec}
    You may want to add the following to your .bash_profile:
      export JBOSS_HOME=#{opt_libexec}
      export PATH=${PATH}:${JBOSS_HOME}/bin
    EOS
  end

  test do
    system "#{opt_libexec}/bin/standalone.sh --version | grep #{version}"
  end
end
