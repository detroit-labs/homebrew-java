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

    Kernel.system({ "JBOSS_HOME" => libexec.to_s }, patch_script)
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

  def patch_script; <<-EOS.undent
    set -e

    readonly BAD_VERSION="2.5.4"
    readonly GOOD_VERSION="2.6.3"
    readonly PACKAGES=(
      core/jackson-core
      core/jackson-annotations
      core/jackson-databind
      jaxrs/jackson-jaxrs-base
      jaxrs/jackson-jaxrs-json-provider
      modules/jackson-module-jaxb-annotations
    )

    readonly BASE_PATH="${JBOSS_HOME}/modules/system/layers/base/com/fasterxml/jackson"
    readonly JAXRS_DIR_PATH="${BASE_PATH}/jaxrs/jackson-jaxrs-json-provider/main"
    readonly BASE_URL="https://jcenter.bintray.com/com/fasterxml/jackson"

    __package_dir_path() {
      if [[ "$1" = *jax* ]]; then
        printf "%s" "${JAXRS_DIR_PATH}"
      else
        printf "%s/%s/main" "${BASE_PATH}" "$1"
      fi
    }

    __package_jar_path() {
      local package_name="$(basename "$1")"
      printf "%s/%s-%s.jar" \\
             "$(__package_dir_path "$1")" \\
             "${package_name}" \\
             "$2"
    }

    __package_config_path() {
      printf "%s/module.xml" "$(__package_dir_path "$1")"
    }

    __package_url() {
      local package="$1"
      printf "%s" "${BASE_URL}/$1/$2/$(basename "${package}")-$2.jar"
    }

    __package_perl() {
      local package_name="$(basename "$1")"
      local from="${package_name}-$2.jar"
      local to="${package_name}-$3.jar"
      printf "s#%s#%s#g;" "${from}" "${to}"
    }

    package_download() {
      local url="$(__package_url "$1" "$2")"
      local path="$(__package_jar_path "$1" "$2")"
      local jar_name="$(basename "${path}")"

      if [[ -e "${path}" ]]; then
        return
      fi
      curl --silent --location --output "${path}" "${url}"
    }

    package_configure() {
      local path="$(__package_config_path "$1")"
      perl -pi \\
           -e "$(__package_perl "$1" "$2" "$3")" \\
           "${path}"
    }

    package_remove() {
      local path="$(__package_jar_path "$1" "$2")"
      local jar_name="$(basename "${path}")"

      if [[ ! -e "${path}" ]]; then
        return
      fi
      rm -f "${path}"
    }

    printf "Patching WildFly Jackson modules to match specified versions...\\n"

    for package in "${PACKAGES[@]}"; do
      printf "* $(basename "${package}")...\\n"
      package_download "${package}" "${GOOD_VERSION}"
      package_configure "${package}" "${BAD_VERSION}" "${GOOD_VERSION}"
      package_remove "${package}" "${BAD_VERSION}"
    done

    printf "Done.\\n"
    EOS
  end

  test do
    system "#{opt_libexec}/bin/standalone.sh --version | grep #{version}"
  end
end
