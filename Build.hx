import sys.io.File;
import sys.FileSystem;
import haxe.io.Bytes;
import StringTools;
import haxe.Json;

// Set default values for command line arguments
class CommandLineArgs {
    public var updateLibs: Bool; // Indicates whether to update libraries such as hashlink and SDL
    public var outputDir: String; // Directory for C source output
    public var libraryName: String; // The name of the dynamic library for the game
    public var gameMain: String; // The entry point of the game
    public var installDir: String; // Installation directory, not used in Android, just for testing

    public function new() {
        // Set to false to prevent automatic updates during build
        updateLibs = false;

        // Directory for C source output
        outputDir = "android/app/src/main/cpp/haxe";

        // The name of the dynamic library for the game
        libraryName = "mygame";

        // The entry point of the game
        gameMain = "Test";

        // Installation directory, not used in Android, just for testing
        installDir = "install";
    }
}

class Build {
    static function runGitCommand(args: Array<String>, workingDir: String = null, maxRetries: Int = 3): Bool {
        var originalDir = Sys.getCwd();
        var process: sys.io.Process = null;
        var success = false;
        var retryCount = 0;
        
        while (retryCount < maxRetries && !success) {
            try {
                if (workingDir != null && FileSystem.exists(workingDir)) {
                    // Change to the specified working directory
                    Sys.setCwd(workingDir);
                }
                process = new sys.io.Process("git", args);
                success = process.exitCode() == 0;
                
                // Output any error messages
                var error = process.stderr.readAll().toString();
                if (error.length > 0) {
                    Sys.stderr().writeString(error);
                }
                
                if (!success && retryCount < maxRetries - 1) {
                    Sys.println('Command failed, retrying (${retryCount + 1}/$maxRetries)...');
                    Sys.sleep(2); // Wait 2 seconds before retrying
                }
            } catch (e: Dynamic) {
                Sys.stderr().writeString('Error executing git command: $e\n');
                if (retryCount < maxRetries - 1) {
                    Sys.println('Command failed, retrying (${retryCount + 1}/$maxRetries)...');
                    Sys.sleep(2); // Wait 2 seconds before retrying
                }
            }
            
            if (process != null) {
                process.close();
                process = null;
            }
            
            retryCount++;
        }
        
        // Restore the original directory
        Sys.setCwd(originalDir);
        
        return success;
    }

    static function cloneOrUpdateRepo(repoUrl: String, targetDir: String, branch: String = null, forceUpdate: Bool) {
        if (!sys.FileSystem.exists(targetDir)) {
            Sys.println('Cloning $repoUrl to $targetDir...');
            if (!runGitCommand(["clone", repoUrl, targetDir])) {
                throw 'Failed to clone repository: $repoUrl';
            }
            if (branch != null) {
                Sys.println('Checking out branch: $branch');
                if (!runGitCommand(["checkout", branch], targetDir)) {
                    throw 'Failed to checkout branch: $branch';
                }
            }
        } else if (forceUpdate) {
            Sys.println('Updating $targetDir...');

            // Fetch the latest code
            if (!runGitCommand(["fetch", "origin"], targetDir)) {
                throw 'Failed to fetch updates for: $targetDir';
            }

            // If a branch is specified, switch to that branch
            if (branch != null) {
                if (!runGitCommand(["checkout", branch], targetDir)) {
                    throw 'Failed to checkout branch: $branch';
                }
            }

            // Reset to the latest state of the remote branch
            var resetTarget = branch != null ? 'origin/${branch}' : 'origin/HEAD';
            if (!runGitCommand(["reset", "--hard", resetTarget], targetDir)) {
                throw 'Failed to update: $targetDir';
            }
        }
    }

    static function setupLibraries(forceUpdate: Bool) {
        // Create libs directory
        if (!sys.FileSystem.exists("libs")) {
            sys.FileSystem.createDirectory("libs");
        }

        // Clone or update HashLink
        cloneOrUpdateRepo(
            "https://github.com/HaxeFoundation/hashlink",
            "libs/hashlink",
            null,
            forceUpdate
        );

        // Clone or update SDL, using SDL2 branch
        cloneOrUpdateRepo(
            "https://github.com/libsdl-org/SDL.git",
            "libs/SDL",
            "SDL2",
            forceUpdate
        );
    }

    static function main() {
        // Initialize default values
        var args = new CommandLineArgs();

        // Parse command line arguments
        var inputArgs = Sys.args();
        for (i in 0...inputArgs.length) {
            if (inputArgs[i] == "--update-libs") {
                args.updateLibs = true;
            }
        }

        // Use the new argument structure
        var updateLibs = args.updateLibs;
        var outputDir = args.outputDir;
        var libraryName = args.libraryName;
        var gameMain = args.gameMain;
        var installDir = args.installDir;

        // Set up dependencies
        setupLibraries(updateLibs);

        // Ensure output directory exists
        if (!FileSystem.exists(outputDir)) {
            FileSystem.createDirectory(outputDir);
        }

        // Build HXML content
        var hxmlContent = [
            "# Common settings",
            '-D work-dir=${outputDir}',
            '-D library-name=${libraryName}',
            '-D install-dir=${installDir}',
            "",
            "--each",
            "",
            "-lib heaps",
            "-lib format",
            "-lib hlsdl",
            '--main ${gameMain}',
            '--hl ${outputDir}/${libraryName}.hl',
            "",
            "--next",
            "",
            "# Build C source",
            "-lib heaps",
            "-lib format",
            "-lib hlsdl",
            '--main ${gameMain}',
            '--hl ${outputDir}/${libraryName}.c',
            "",
            "--next",
            "",
            "# Run Hlc2Cmake,Hlc2Cmake.hx need -D defined in .build.hxml ",
            "--main Hlc2Cmake",
            "--run Hlc2Cmake"
        ];

        var hxmlPath = ".build.hxml";
        File.saveContent(hxmlPath, hxmlContent.join("\n"));
        Sys.println('Generated ${hxmlPath}');

        // Execute HXML, call command: haxe .build.hxml
        Sys.println('Running haxe ${hxmlPath}...');
        var process = new sys.io.Process('haxe', [hxmlPath]);
        var exitCode = process.exitCode();

        // Output compilation results
        var output = process.stdout.readAll().toString();
        var error = process.stderr.readAll().toString();
        if (output.length > 0) Sys.println(output);
        if (error.length > 0) {
            Sys.stderr().writeString(error);
            Sys.exit(1); // Terminate execution on error
        }

        // Check compilation results
        if (exitCode != 0) {
            Sys.println('Build failed with exit code ${exitCode}');
            Sys.exit(exitCode);
        } else {
            Sys.println('Build completed successfully!');
        }
    }
}
