import sys.io.File;
import sys.FileSystem;
import haxe.io.Bytes;
import StringTools;

class Build {
    static function runGitCommand(args: Array<String>, workingDir: String = null, maxRetries: Int = 3): Bool {
        var originalDir = Sys.getCwd();
        var process: sys.io.Process = null;
        var success = false;
        var retryCount = 0;
        
        while (retryCount < maxRetries && !success) {
            try {
                if (workingDir != null && FileSystem.exists(workingDir)) {
                    Sys.setCwd(workingDir);
                }
                process = new sys.io.Process("git", args);
                success = process.exitCode() == 0;
                
                // 输出任何错误信息
                var error = process.stderr.readAll().toString();
                if (error.length > 0) {
                    Sys.stderr().writeString(error);
                }
                
                if (!success && retryCount < maxRetries - 1) {
                    Sys.println('Command failed, retrying (${retryCount + 1}/$maxRetries)...');
                    Sys.sleep(2); // 等待 2 秒后重试
                }
            } catch (e: Dynamic) {
                Sys.stderr().writeString('Error executing git command: $e\n');
                if (retryCount < maxRetries - 1) {
                    Sys.println('Command failed, retrying (${retryCount + 1}/$maxRetries)...');
                    Sys.sleep(2); // 等待 2 秒后重试
                }
            }
            
            if (process != null) {
                process.close();
                process = null;
            }
            
            retryCount++;
        }
        
        // 恢复原来的工作目录
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

            // 拉取最新代码
            if (!runGitCommand(["fetch", "origin"], targetDir)) {
                throw 'Failed to fetch updates for: $targetDir';
            }

            // 如果指定了分支，就切换到该分支
            if (branch != null) {
                if (!runGitCommand(["checkout", branch], targetDir)) {
                    throw 'Failed to checkout branch: $branch';
                }
            }

            // 重置到远程分支的最新状态
            var resetTarget = branch != null ? 'origin/${branch}' : 'origin/HEAD';
            if (!runGitCommand(["reset", "--hard", resetTarget], targetDir)) {
                throw 'Failed to update: $targetDir';
            }
        }
    }

    static function setupLibraries(forceUpdate: Bool) {
        // 创建 libs 目录
        if (!sys.FileSystem.exists("libs")) {
            sys.FileSystem.createDirectory("libs");
        }

        // 克隆或更新 HashLink
        cloneOrUpdateRepo(
            "https://github.com/HaxeFoundation/hashlink",
            "libs/hashlink",
            null,
            forceUpdate
        );

        // 克隆或更新 SDL，使用 SDL2 分支
        cloneOrUpdateRepo(
            "https://github.com/libsdl-org/SDL.git",
            "libs/SDL",
            "SDL2",
            forceUpdate
        );
    }

    static function main() {
        // 解析命令行参数
        var args = Sys.args();
        var updateLibs = false;
        var outputDir = "out";
        var libraryName = "mygame";
        var gameMain = "Test";
        var installDir = "install";

        for (i in 0...args.length) {
            if (args[i] == "--update-libs") {
                updateLibs = true;
            }
        }

        // 设置依赖库
        setupLibraries(updateLibs);

        // 构建 HXML 内容
        var hxmlContent = [
            "# Common settings",
            '-D work-dir=${outputDir}',
            '-D library-name=${libraryName}',
            '-D install-dir=${installDir}',
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
            "# Run Hlc2Cmake",
            "--main Hlc2Cmake",
            "--run Hlc2Cmake"
        ];

        // 确保输出目录存在
        if (!FileSystem.exists(outputDir)) {
            FileSystem.createDirectory(outputDir);
        }

        // 写入 HXML 文件
        var hxmlPath = ".build.hxml";
        File.saveContent(hxmlPath, hxmlContent.join("\n"));
        Sys.println('Generated ${hxmlPath}');

        // 执行 HXML
        Sys.println('Running haxe ${hxmlPath}...');
        var process = new sys.io.Process('haxe', [hxmlPath]);
        var exitCode = process.exitCode();
        
        // 输出编译结果
        var output = process.stdout.readAll().toString();
        var error = process.stderr.readAll().toString();
        
        if (output.length > 0) Sys.println(output);
        if (error.length > 0) {
            var bytes = Bytes.ofString(error);
            Sys.stderr().writeBytes(bytes, 0, bytes.length);
        }
        
        process.close();

        // 检查编译结果
        if (exitCode != 0) {
            Sys.println('Build failed with exit code ${exitCode}');
            Sys.exit(exitCode);
        } else {
            Sys.println('Build completed successfully!');
        }
    }
}
