import haxe.Template;
import sys.io.File;
import haxe.Json;
import sys.FileSystem;
import haxe.io.Path;

class Hlc2Cmake {
    static final template_path = "cmake_template.cmake";

    static function getConfig() {
        // Get values from compiler defines (-D options)
        var workDir = haxe.macro.Compiler.getDefine("work-dir");
        var libraryName = haxe.macro.Compiler.getDefine("library-name");
        var installDir = haxe.macro.Compiler.getDefine("install-dir");
        var isAndroid = haxe.macro.Compiler.getDefine("android") != null;

        // compute relative path from workdir to libs,used in cmake file
        var libsPath = Path.join([Sys.getCwd(), "libs"]);
        var sourcePath = if (Path.isAbsolute(workDir)) {
            workDir;
        } else {
            Path.join([Sys.getCwd(), workDir]);
        }
        var libsRelativePath = getRelative(sourcePath, libsPath);
       
        // Use default values if not defined
        // if (workDir == null) workDir = "jni/app/src/main/cpp/haxe";
        // if (libraryName == null) libraryName = "mygame";
        // if (installDir == null) installDir = "install";

        return { workDir: workDir, libsRelativePath: libsRelativePath, libraryName: libraryName, installDir: installDir, isAndroid: isAndroid };
    }

    public static function getRelative(fromPath:String, toPath:String):String {

        var fromParts = Path.normalize(fromPath).split("/");
        var toParts = Path.normalize(toPath).split("/");

        var commonIndex = 0;
        while (commonIndex < fromParts.length && commonIndex < toParts.length && fromParts[commonIndex] == toParts[commonIndex]) {
            commonIndex++;
        }

        var upLevels = fromParts.length - commonIndex;
        var relativeParts = [];
        for (i in 0...upLevels) {
            relativeParts.push("..");
        }

        for (i in commonIndex...toParts.length) {
            relativeParts.push(toParts[i]);
        }
        return relativeParts.join("/");
    }

    public static function main() {
        // Get configuration from compiler defines
        var config = getConfig();

        var workDir = config.workDir;
        var libsRelativePath = config.libsRelativePath;
        var libraryName = config.libraryName;
        var installDir = config.installDir;
        var isAndroid = config.isAndroid;

        // Construct file paths
        // 使用 workDir 作为基础路径
        var hlcJsonPath = '${workDir}/hlc.json';
        var cmakeListsPath = '${workDir}/CMakeLists.txt';
        Sys.println('Generating files in: ${workDir}');

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

            HASHLINK_SOURCE_DIR: Path.join([libsRelativePath,"hashlink"]), //"${CMAKE_SOURCE_DIR}/../libs/hashlink",
            HASHLINK_LIBRARY_DIR: "${CMAKE_BINARY_DIR}/hashlink",

            SDL_SOURCE_DIR: Path.join([libsRelativePath,"SDL"]), //"${CMAKE_SOURCE_DIR}/../libs/SDL",
            SDL_LIBRARY_DIR: "${CMAKE_BINARY_DIR}/SDL",

            INSTALL_DIR: installDir,
            
            // 添加Android标志
            IS_ANDROID: isAndroid ? "TRUE" : "FALSE",
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