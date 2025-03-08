# HLC2CMAKE

[Click here for English Description](#english-description)

## 中文说明

这是一个用于将 Haxe/Heaps 游戏项目转换为 CMake 构建系统的工具。它可以自动处理依赖关系，生成 CMake 配置文件，并支持动态库的构建和安装。

### 主要功能

1. **自动依赖管理**
   - 自动克隆 HashLink 和 SDL 依赖
   - 支持通过 `./run.sh --update-libs` 参数更新依赖库
   - 保持 SDL 在 SDL2 分支，因为haxe的库hlsdl，依赖的是SDL2（2025-03-09），虽然也试过SDL3能编译通过，但是还是按照hlsdl的要求使用SDL2版本
   - clone时遇到网络问题重试，三次

2. **构建系统生成**
   - 将 Haxe 代码编译为 C 代码
   - 生成 CMake 配置文件
   - 配置动态库的构建和安装
   - 自动处理库的依赖关系

3. **安装配置**
   - 所有生成的文件统一安装到指定目录
   - 支持动态库和可执行文件的安装
   - 正确处理运行时依赖

### 项目结构

```
.
├── Build.hx              # 构建脚本，处理依赖和编译
├── Hlc2Cmake.hx         # CMake 配置生成器
├── Test.hx              # 示例游戏代码
├── cmake_template.cmake  # CMake 模板文件
├── run.sh               # 构建启动脚本
└── libs/                # 依赖库目录（自动创建）
    ├── hashlink/        # HashLink 运行时
    └── SDL/            # SDL 库（SDL2 分支）
```

### 构建流程

1. **依赖管理**
   - 检查 `libs` 目录是否存在，不存在则创建
   - 克隆或更新 HashLink 和 SDL 仓库
   - SDL 仓库会保持在 SDL2 分支

2. **代码生成**
   - 生成 HXML 构建配置 .build.hxml
   - 调用haxe .build.hxml，编译 Haxe 代码为 C 代码
   - 生成 CMake 配置文件

3. **CMake 配置**
   - 配置动态库构建
   - 设置安装路径
   - 配置依赖关系

4. **一些设置细节**
   - 编译的输出路径，生成的库名称，安装的路径，都可以修改Hlc2Cmake.hx文件指定
   - 编译hashlink时，跳过了虚拟机hl的编译
   - 调整hashlink和SDL2,在make install时，有关的文件都输出到 out/install目录

### 使用方法

1. **基本构建**：
   ```bash
   ./run.sh
   ```

2. **更新依赖**：
   ```bash
   ./run.sh --update-libs
   ```

### 注意事项

- 首次运行会自动下载依赖
- 不使用 `--update-libs` 时保持依赖库现状
- 使用 `--update-libs` 时会更新到最新代码，但 SDL 会保持在 SDL2 分支

## English Description

# HLC2CMAKE

A tool for converting Haxe/Heaps game projects to CMake build system. It automatically handles dependencies, generates CMake configuration files, and supports dynamic library building and installation.

### Main Features

1. **Automatic Dependency Management**
   - Automatically clones HashLink and SDL dependencies
   - Supports dependency updates via `./run.sh --update-libs` parameter
   - Maintains SDL on SDL2 branch, as the haxe library hlsdl depends on SDL2 (as of 2025-03-09). While SDL3 compilation is possible, we stick to SDL2 as per hlsdl requirements
   - Includes 3 retries for network issues during cloning

2. **Build System Generation**
   - Compiles Haxe code to C code
   - Generates CMake configuration files
   - Configures dynamic library building and installation
   - Automatically handles library dependencies

3. **Installation Configuration**
   - All generated files are installed to a specified directory
   - Supports installation of dynamic libraries and executables
   - Properly handles runtime dependencies

### Project Structure

```
.
├── Build.hx              # Build script, handles dependencies and compilation
├── Hlc2Cmake.hx         # CMake configuration generator
├── Test.hx              # Example game code
├── cmake_template.cmake  # CMake template file
├── run.sh               # Build launcher script
└── libs/                # Dependencies directory (auto-created)
    ├── hashlink/        # HashLink runtime
    └── SDL/            # SDL library (SDL2 branch)
```


### Build Process

1. **Dependency Management**
   - Checks if `libs` directory exists, creates if not
   - Clones or updates HashLink and SDL repositories
   - SDL repository is maintained on SDL2 branch

2. **Code Generation**
   - Generates HXML build configuration (.build.hxml)
   - Runs `haxe .build.hxml` to compile Haxe code to C code
   - Generates CMake configuration file

3. **CMake Configuration**
   - Configures dynamic library building
   - Sets installation paths
   - Configures dependencies

4. **Configuration Details**
   - Build output path, library name, and installation path can be modified in Hlc2Cmake.hx
   - Skips compilation of the hl virtual machine when building hashlink
   - Adjusts hashlink and SDL2 installation to output all related files to out/install directory

### Usage

1. **Basic Build**:
   ```bash
   ./run.sh
   ```

2. **Update Dependencies**:
   ```bash
   ./run.sh --update-libs
   ```

### Notes

- Dependencies are automatically downloaded on first run
- Dependencies remain unchanged without `--update-libs`
- `--update-libs` updates to latest code, but SDL stays on SDL2 branch
