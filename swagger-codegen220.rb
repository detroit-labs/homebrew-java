class SwaggerCodegen220 < Formula
  desc "Generation of client and server from Swagger definition"
  homepage "http://swagger.io/swagger-codegen/"
  url "https://github.com/swagger-api/swagger-codegen/archive/v2.2.0.tar.gz"
  sha256 "4c0ba632e9da193c278b00bbb59deab68206a588b381de764d614e77ca99f171"

  conflicts_with "swagger-codegen", :because => "Only one version of swagger-codegen may be installed"

  depends_on :java => "1.7+"
  depends_on "maven" => :build

  def install
    ENV.java_cache

    system "mvn", "clean", "package"
    libexec.install "modules/swagger-codegen-cli/target/swagger-codegen-cli.jar"
    bin.write_jar_script libexec/"swagger-codegen-cli.jar", "swagger-codegen"
  end

  test do
    (testpath/"minimal.yaml").write <<-EOS.undent
      ---
      swagger: '2.0'
      info:
        version: 0.0.0
        title: Simple API
      paths:
        /:
          get:
            responses:
              200:
                description: OK
    EOS
    system "#{bin}/swagger-codegen", "generate", "-i", "minimal.yaml", "-l", "swagger"
  end
end
