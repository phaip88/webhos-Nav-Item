# 部署指南 (Deployment Guide)

## ✅ 预编译版本 (Pre-compiled Version)

本仓库包含预编译的生产版本，可直接部署无需构建前端。

### 快速部署到 Leapcell 或其他平台

#### 1. 构建配置
```
Build Command: npm install
# 或留空（如果平台支持）
```

#### 2. 启动配置
```
Start Command: npm start
```

#### 3. 环境变量（可选）
```
PORT=3000                    # 服务器端口（默认: 3000）
ADMIN_USERNAME=admin         # 管理员用户名（默认: admin）
ADMIN_PASSWORD=123456        # 管理员密码（默认: 123456）
NODE_ENV=production         # 生产环境
```

#### 4. 持久化目录（推荐挂载）
- `/app/database` - SQLite 数据库文件
- `/app/uploads` - 用户上传的文件

### 部署优势
- ✅ **无需构建前端** - 前端已预编译在 `web/dist/` 目录
- ✅ **快速部署** - 只需安装依赖即可启动
- ✅ **减少构建时间** - 节省平台构建资源
- ✅ **降低失败风险** - 避免前端构建过程中的潜在问题

### 技术细节
- 前端构建产物位于 `web/dist/` 目录
- Express 静态文件服务自动提供前端资源
- 所有 `/api` 路由由 Express 后端处理
- 其他路由返回 `index.html` 实现 SPA 路由

## 🔧 开发环境

如果需要修改前端代码并重新构建：

### 1. 安装依赖
```bash
# 安装后端依赖
npm install

# 安装前端依赖
cd web && npm install
```

### 2. 开发模式
```bash
# 启动后端（端口 3000）
npm run dev

# 启动前端开发服务器（端口 5173，在另一个终端）
cd web && npm run dev
```

### 3. 生产构建
```bash
# 构建前端
cd web && npm run build

# 或使用根目录的构建脚本
npm run build
```

### 4. 提交更新
```bash
# 添加构建产物
git add web/dist/

# 提交
git commit -m "build: update frontend build"

# 推送
git push
```

## 📦 项目结构

```
nav-item/
├── app.js                 # Express 服务器入口
├── package.json          # 后端依赖配置
├── database/             # SQLite 数据库
├── routes/               # API 路由
├── uploads/              # 用户上传文件
├── web/
│   ├── dist/            # 🔥 预编译前端（已提交到 Git）
│   ├── src/             # 前端源代码
│   ├── package.json     # 前端依赖配置
│   └── vite.config.mjs  # Vite 配置
└── .gitignore           # Git 忽略配置
```

## 🚀 部署检查清单

- [x] 前端已构建 (`web/dist/` 存在且完整)
- [x] `package.json` 包含 `start` 脚本
- [x] `.gitignore` 正确配置（排除 `node_modules/`）
- [x] 数据库文件 `database/nav.db` 存在
- [x] 环境变量已配置（如需要）
- [x] 已推送到远程仓库

## 📝 常见问题

### Q: 为什么提交构建产物到 Git？
A: 为了简化部署流程，特别是在资源受限的平台上。这样可以跳过前端构建步骤，直接运行应用。

### Q: 如何更新前端？
A: 修改 `web/src/` 下的源代码，运行 `npm run build`，然后提交 `web/dist/` 的变更。

### Q: 数据库如何初始化？
A: 应用首次启动时会自动创建数据库并初始化默认数据（参见 `db.js`）。

### Q: 如何修改管理员密码？
A: 通过环境变量 `ADMIN_PASSWORD` 设置，或在后台管理界面修改。

## 🔗 相关资源

- [主 README](README.md) - 完整项目文档
- [Dockerfile](Dockerfile) - Docker 部署配置
- [API 文档](routes/) - 后端 API 接口说明

---

**提示**: 本文档专为预编译部署优化。如需完整开发指南，请参考 [README.md](README.md)。
