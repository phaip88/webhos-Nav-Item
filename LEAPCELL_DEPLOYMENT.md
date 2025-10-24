# Leapcell 部署配置指南

## 项目信息

- **项目名称**: mao_nav (Nav-Item)
- **项目类型**: Node.js (Express) 全栈应用
- **Node版本要求**: >= 14 (推荐 18 或 20)

## 入口文件信息

✅ **主入口文件**: `app.js`
✅ **启动脚本**: 已配置在 package.json

## Leapcell 部署配置

### 1. 基本配置

#### 启动命令 (Start Command)
```bash
npm start
```

或者直接使用:
```bash
node app.js
```

#### 构建命令 (Build Command)
```bash
npm install && cd web && npm install && npm run build
```

### 2. 环境变量配置

在 Leapcell 控制台设置以下环境变量:

| 变量名 | 说明 | 默认值 | 必填 |
|--------|------|--------|------|
| `PORT` | 服务器端口 | 3000 | ❌ (Leapcell会自动分配) |
| `ADMIN_USERNAME` | 后台管理用户名 | admin | ✅ 推荐修改 |
| `ADMIN_PASSWORD` | 后台管理密码 | 123456 | ✅ 强烈推荐修改 |
| `JWT_SECRET` | JWT密钥 | nav-item-jwt-secret-2024-secure-key | ✅ 推荐修改 |
| `NODE_ENV` | 运行环境 | production | ❌ |

**示例环境变量配置:**
```
ADMIN_USERNAME=your_admin_username
ADMIN_PASSWORD=your_secure_password
JWT_SECRET=your-random-jwt-secret-key-here
NODE_ENV=production
```

### 3. 持久化存储配置

#### 需要持久化的目录:

1. **数据库目录** (重要)
   - 路径: `/app/database`
   - 说明: 存储 SQLite 数据库文件 (nav.db)
   - 必须持久化: ✅ 是

2. **上传文件目录** (推荐)
   - 路径: `/app/uploads`
   - 说明: 存储用户上传的图片文件
   - 必须持久化: ✅ 推荐

#### Leapcell 持久化卷配置:
```
卷1: /app/database → 数据库存储
卷2: /app/uploads → 上传文件存储
```

### 4. 端口配置

- **监听端口**: 应用已配置为监听 `0.0.0.0:$PORT`
- **Leapcell自动分配**: Leapcell 会通过 `PORT` 环境变量提供端口
- **无需手动配置**: 应用会自动使用 Leapcell 分配的端口

### 5. 健康检查 (Health Check)

可选配置健康检查端点:
- **路径**: `/` 或 `/api/menus`
- **方法**: GET
- **预期响应**: 200 OK

## 部署步骤

### 方式一: 从 GitHub 部署 (推荐)

1. **连接 GitHub 仓库**
   - 在 Leapcell 控制台选择 "从 Git 导入"
   - 授权并选择你的仓库: `https://github.com/eooce/nav-Item.git`
   - 选择分支: `main` 或 `master`

2. **配置构建设置**
   - 构建命令: `npm install && cd web && npm install && npm run build`
   - 启动命令: `npm start`
   - Node 版本: 18.x 或 20.x

3. **配置环境变量**
   - 添加上述提到的环境变量
   - 特别注意修改默认的管理员密码

4. **配置持久化卷**
   - 添加卷挂载: `/app/database`
   - 添加卷挂载: `/app/uploads`

5. **部署**
   - 点击 "部署" 按钮
   - 等待构建和部署完成

### 方式二: 使用 Docker 镜像部署

如果 Leapcell 支持 Docker 部署:

```bash
# 使用预构建的 Docker 镜像
eooce/nav-item:latest
```

或

```bash
ghcr.io/eooce/nav-item:latest
```

**Docker 部署配置:**
- 端口映射: 自动使用 Leapcell 的 PORT
- 环境变量: 同上
- 卷挂载: `/app/database` 和 `/app/uploads`

## 部署验证

部署成功后，访问以下路径验证:

1. **前端首页**: `https://your-app.leapcell.io/`
2. **后台管理**: `https://your-app.leapcell.io/admin`
3. **API测试**: `https://your-app.leapcell.io/api/menus`

### 默认管理员账号
- 用户名: `admin` (或你配置的 ADMIN_USERNAME)
- 密码: `123456` (或你配置的 ADMIN_PASSWORD)

⚠️ **安全提示**: 首次登录后请立即修改默认密码!

## 常见问题排查

### 1. 启动失败: "Missing script: start"
**原因**: package.json 缺少 start 脚本
**解决**: ✅ 已修复 - package.json 已包含 start 脚本

### 2. 启动失败: "Cannot find module"
**原因**: 依赖未正确安装
**解决**: 
- 确保构建命令包含 `npm install`
- 检查 package.json 中的依赖是否完整

### 3. 端口绑定失败
**原因**: 应用未监听正确的端口或主机
**解决**: ✅ 已修复 - app.js 已更新为监听 `0.0.0.0:$PORT`

### 4. 数据丢失
**原因**: 未配置持久化卷
**解决**: 
- 确保 `/app/database` 目录已挂载到持久化卷
- 重新部署后数据会保留

### 5. 上传的图片丢失
**原因**: 未持久化 uploads 目录
**解决**: 
- 确保 `/app/uploads` 目录已挂载到持久化卷

### 6. 前端页面空白
**原因**: 前端未正确构建
**解决**:
- 检查构建日志，确认 `npm run build` 成功
- 确认 `web/dist` 目录已生成

## 性能优化建议

1. **启用压缩**: ✅ 已启用 (compression 中间件)
2. **静态资源缓存**: 考虑配置 CDN
3. **数据库优化**: 定期维护 SQLite 数据库
4. **日志管理**: 配置日志轮转避免磁盘占用过大

## 安全建议

1. ✅ 修改默认管理员密码
2. ✅ 配置强随机 JWT_SECRET
3. 定期更新依赖包: `npm audit fix`
4. 启用 HTTPS (Leapcell 通常自动提供)
5. 配置 CORS 白名单 (如需要)

## 监控和日志

### 查看应用日志
在 Leapcell 控制台:
- 查看 "日志" 标签
- 监控应用启动和运行日志
- 检查错误信息

### 关键日志信息
应用启动成功会显示:
```
server is running at http://0.0.0.0:<PORT>
```

## 扩展资源

- **项目仓库**: https://github.com/eooce/nav-Item
- **Docker Hub**: https://hub.docker.com/r/eooce/nav-item
- **文档**: 查看项目 README.md

## 技术支持

如遇到部署问题:
1. 查看 Leapcell 部署日志
2. 检查本文档的常见问题部分
3. 在项目 GitHub 提交 Issue

---

📅 最后更新: 2024-01-24
📝 文档版本: 1.0
✅ 部署状态: 已优化并验证
