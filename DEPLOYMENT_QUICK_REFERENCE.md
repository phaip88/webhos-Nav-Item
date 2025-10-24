# 快速部署参考 (Leapcell)

## 核心信息

### 📁 入口文件
```
app.js
```

### 🚀 启动命令 (Start Command)
```bash
npm start
```
或
```bash
node app.js
```

### 🔨 构建命令 (Build Command)
```bash
npm install && cd web && npm install && npm run build
```

### 🌐 Node 版本
```
>= 14 (推荐 18 或 20)
```

## 必需的环境变量

```bash
ADMIN_USERNAME=your_admin_username
ADMIN_PASSWORD=your_secure_password
JWT_SECRET=your-random-jwt-secret-key
```

## 持久化卷配置

| 卷路径 | 说明 | 是否必需 |
|--------|------|---------|
| `/app/database` | SQLite 数据库 | ✅ 必需 |
| `/app/uploads` | 上传的图片 | ⭐ 推荐 |

## 完整配置示例

```yaml
# Leapcell 配置
项目类型: Node.js
Node 版本: 20.x
构建命令: npm install && cd web && npm install && npm run build
启动命令: npm start

环境变量:
  - ADMIN_USERNAME=admin
  - ADMIN_PASSWORD=your_password
  - JWT_SECRET=your_jwt_secret
  - NODE_ENV=production

持久化卷:
  - /app/database
  - /app/uploads
```

## 验证部署

访问以下 URL 验证部署:
- 首页: `https://your-app.leapcell.io/`
- 后台: `https://your-app.leapcell.io/admin`
- API: `https://your-app.leapcell.io/api/menus`

## 故障排查

### 如果部署失败:
1. 检查构建日志
2. 确认 `npm install` 成功
3. 确认 `web/npm run build` 成功
4. 确认环境变量已设置
5. 确认持久化卷已挂载

### 常见错误:
- ❌ "Missing script: start" → ✅ 已修复
- ❌ "Cannot find module" → 检查构建命令
- ❌ "EADDRINUSE" → PORT 冲突 (Leapcell会自动处理)

---

详细文档请查看: [LEAPCELL_DEPLOYMENT.md](./LEAPCELL_DEPLOYMENT.md)
