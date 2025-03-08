import haxe.Template;
import sys.io.File;
import haxe.Json;

class Hlc2Cmake {
    static final template_path = "cmake_template.cmake";

    static function getConfig() {
        // Get values from compiler defines (-D options)
        var workDir = haxe.macro.Compiler.getDefine("work-dir");
        var libraryName = haxe.macro.Compiler.getDefine("library-name");
        var installDir = haxe.macro.Compiler.getDefine("install-dir");

        // Use default values if not defined
        if (workDir == null) workDir = "out";
        if (libraryName == null) libraryName = "mygame";
        if (installDir == null) installDir = "install";

        return { workDir: workDir, libraryName: libraryName, installDir: installDir };
    }

    public static function main() {
        // Get configuration from compiler defines
        var config = getConfig();
        var workDir = config.workDir;
        var libraryName = config.libraryName;
        var installDir = config.installDir;

        // Construct file paths
        var hlcJsonPath = '${workDir}/hlc.json';
        var cmakeListsPath = '${workDir}/CMakeLists.txt';

        // Read and parse input JSON
        var jsonContent = try {
            File.getContent(hlcJsonPath);
        } catch (e:Dynamic) {
            Sys.stderr().writeString('Error reading $hlcJsonPath: $e\n');
            Sys.exit(1);
            return;
        }

        var jsonData = try {
            Json.parse(jsonContent);
        } catch (e:Dynamic) {
            Sys.stderr().writeString('Error parsing $hlcJsonPath: $e\n');
            Sys.exit(1);
            return;
        }

        // Make sure jsonData.files is an array
        var files:Array<String> = jsonData.files;
        if (files == null || files.length == 0) {
            Sys.stderr().writeString('Error: No files found in $hlcJsonPath\n');
            Sys.exit(1);
            return;
        }

        var tplParams = {
            PROJECT_NAME: libraryName,
            ENTRY_POINT: files[0],

            HASHLINK_SOURCE_DIR: "${CMAKE_SOURCE_DIR}/../libs/hashlink",
            HASHLINK_LIBRARY_DIR: "${CMAKE_BINARY_DIR}/hashlink",

            SDL_SOURCE_DIR: "${CMAKE_SOURCE_DIR}/../libs/SDL",
            SDL_LIBRARY_DIR: "${CMAKE_BINARY_DIR}/SDL",

            INSTALL_DIR: installDir,
        };

        // Read template
        var tpl = try {
            new Template(File.getContent(template_path));
        } catch (e:Dynamic) {
            Sys.stderr().writeString('Error reading template $template_path: $e\n');
            Sys.exit(1);
            return;
        }

        var result = tpl.execute(tplParams);

        // Save output
        try {
            File.saveContent(cmakeListsPath, result);
            Sys.println('CMakeLists.txt generated successfully at $cmakeListsPath');
        } catch (e:Dynamic) {
            Sys.stderr().writeString('Error writing to $cmakeListsPath: $e\n');
            Sys.exit(1);
        }
    }
}