# Node.js 应用部署完整指南

## 📋 项目概述

本文档提供了在webhostmost.com平台上部署Node.js应用的完整解决方案，包括构建模式和非构建模式两种部署方式。

## 🎯 部署目标

- **应用**: webhos-Nav-Item (Node.js导航应用)
- **平台**: webhostmost.com (CloudLinux + LiteSpeed + Passenger)
- **目标**: 实现HTTP和HTTPS双协议访问

## 📊 平台环境分析

### 实际测试环境配置
- **操作系统**: CloudLinux
- **Web服务器**: LiteSpeed + Passenger
- **Node.js版本**: 20.19.4 (系统预装)
- **npm版本**: 10.8.2
- **部署方式**: 传统Passenger配置
- **测试服务器**: sv62 (成功), sv8 (HTTP成功, HTTPS有问题)

### 实际目录结构
```
~/domains/域名/
├── public_html/        # HTTP目录 (主要部署位置)
│   ├── app.js         # 应用入口文件
│   ├── .htaccess      # Passenger配置
│   ├── node_modules/  # 依赖包 (完整版本包含)
│   ├── web/dist/      # 前端构建文件
│   ├── routes/        # API路由
│   ├── uploads/       # 上传文件目录
│   └── tmp/           # 临时文件目录
└── private_html/      # HTTPS目录 (可选，某些服务器需要)
```

## 🚀 方案一：非构建模式部署（推荐）

### 适用场景
- 快速部署，无需构建过程
- 使用预构建的完整版本
- 避免服务器端npm install问题
- 适合生产环境部署

### 步骤1: 获取完整部署包

```bash
# 从GitHub下载预构建的完整版本
wget https://github.com/phaip88/webhos-Nav-Item/raw/master/webhos-nav-item-complete.tar.gz

# 或者使用本地已有的完整版本
# webhos-nav-item-complete.tar.gz (25MB)
# 包含: node_modules/, web/dist/, 所有源码文件
```

### 步骤2: 服务器部署

```bash
# 1. 分析平台环境
ssh 服务器 "pwd && whoami"
ssh 服务器 "ls -la ~/domains/"
ssh 服务器 "ls -la /opt/alt/alt-nodejs20/root/usr/bin/node"

# 2. 清理目标目录 (保留public_html目录结构)
ssh 服务器 "cd ~/domains/域名/public_html && rm -f index.html favicon.svg && rm -rf cgi-bin"

# 3. 上传部署包
scp webhos-nav-item-complete.tar.gz 服务器:~/

# 4. 解压到目标目录
ssh 服务器 "cd ~/domains/域名/public_html && tar -xzf ~/webhos-nav-item-complete.tar.gz"

# 5. 配置.htaccess (关键步骤)
ssh 服务器 "cd ~/domains/域名/public_html && cat > .htaccess << 'EOF'
PassengerEnabled On
PassengerAppRoot /home/用户名/domains/域名/public_html
PassengerStartupFile app.js
PassengerAppType node
PassengerNodejs /opt/alt/alt-nodejs20/root/usr/bin/node
PassengerAppEnv production

SetEnv NODE_ENV production
EOF"

# 6. 启动应用
ssh 服务器 "cd ~/domains/域名/public_html && touch tmp/restart.txt"

# 7. 验证部署
ssh 服务器 "curl -I http://域名/"
```

### 实际部署示例 (sv62成功案例)

```bash
# 实际执行的命令
scp webhos-nav-item-complete.tar.gz sv62:~/
ssh sv62 "cd ~/domains/runx.sylu.net/public_html && tar -xzf ~/webhos-nav-item-complete.tar.gz"
ssh sv62 "cd ~/domains/runx.sylu.net/public_html && cat > .htaccess << 'EOF'
PassengerEnabled On
PassengerAppRoot /home/uozomgpa/domains/runx.sylu.net/public_html
PassengerStartupFile app.js
PassengerAppType node
PassengerNodejs /opt/alt/alt-nodejs20/root/usr/bin/node
PassengerAppEnv production

SetEnv NODE_ENV production
EOF"
ssh sv62 "cd ~/domains/runx.sylu.net/public_html && touch tmp/restart.txt"
```

## 🚀 方案二：一键部署脚本（自动化）

### 适用场景
- 批量部署多个服务器
- 自动化部署流程
- 减少手动操作错误
- 标准化部署过程

### 步骤1: 使用一键部署脚本

使用提供的部署脚本 `deploy.sh`:

```bash
#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   Node.js 应用一键部署脚本${NC}"
echo -e "${BLUE}========================================${NC}"

# 获取参数
SERVER=$1
DOMAIN=$2
PACKAGE=$3

if [ -z "$SERVER" ] || [ -z "$DOMAIN" ] || [ -z "$PACKAGE" ]; then
    echo -e "${RED}用法: $0 <服务器> <域名> <部署包>${NC}"
    echo -e "${YELLOW}示例: $0 sv62 runx.sylu.net webhos-nav-item-complete.tar.gz${NC}"
    exit 1
fi

echo -e "${YELLOW}部署配置:${NC}"
echo -e "  服务器: $SERVER"
echo -e "  域名: $DOMAIN"
echo -e "  部署包: $PACKAGE"
echo ""

# 检查部署包是否存在
if [ ! -f "$PACKAGE" ]; then
    echo -e "${RED}错误: 部署包 $PACKAGE 不存在${NC}"
    exit 1
fi

# 1. 分析平台环境
echo -e "${GREEN}[1/7] 分析平台环境...${NC}"
USERNAME=$(ssh $SERVER "whoami")
NODE_PATH=$(ssh $SERVER "ls /opt/alt/alt-nodejs20/root/usr/bin/node 2>/dev/null || echo '/opt/alt/alt-nodejs18/root/usr/bin/node'")

echo -e "${GREEN}  用户名: $USERNAME${NC}"
echo -e "${GREEN}  Node.js: $NODE_PATH${NC}"

# 2. 检查目录结构
echo -e "${GREEN}[2/7] 检查目录结构...${NC}"
ssh $SERVER "ls -la ~/domains/$DOMAIN/ 2>/dev/null || echo '目录不存在'"

# 3. 清理目标目录
echo -e "${GREEN}[3/7] 清理目标目录...${NC}"
ssh $SERVER "cd ~/domains/$DOMAIN/public_html 2>/dev/null && rm -f index.html favicon.svg && rm -rf cgi-bin || echo '目录为空'"

# 4. 上传部署包
echo -e "${GREEN}[4/7] 上传部署包...${NC}"
scp $PACKAGE $SERVER:~/
echo -e "${GREEN}  上传完成${NC}"

# 5. 解压到目标目录
echo -e "${GREEN}[5/7] 解压部署包...${NC}"
ssh $SERVER "cd ~/domains/$DOMAIN/public_html && tar -xzf ~/$(basename $PACKAGE)"
echo -e "${GREEN}  解压完成${NC}"

# 6. 配置.htaccess
echo -e "${GREEN}[6/7] 配置.htaccess...${NC}"
ssh $SERVER "cd ~/domains/$DOMAIN/public_html && cat > .htaccess << 'EOF'
PassengerEnabled On
PassengerAppRoot /home/$USERNAME/domains/$DOMAIN/public_html
PassengerStartupFile app.js
PassengerAppType node
PassengerNodejs $NODE_PATH
PassengerAppEnv production

SetEnv NODE_ENV production
EOF"
echo -e "${GREEN}  配置完成${NC}"

# 7. 启动应用
echo -e "${GREEN}[7/7] 启动应用...${NC}"
ssh $SERVER "cd ~/domains/$DOMAIN/public_html && touch tmp/restart.txt"
echo -e "${GREEN}  启动完成${NC}"

# 验证部署
echo -e "${GREEN}验证部署结果...${NC}"
sleep 5
HTTP_STATUS=$(ssh $SERVER "curl -s -o /dev/null -w '%{http_code}' http://$DOMAIN/")
if [ "$HTTP_STATUS" = "200" ]; then
    echo -e "${GREEN}✅ HTTP访问正常 (200)${NC}"
else
    echo -e "${RED}❌ HTTP访问异常 ($HTTP_STATUS)${NC}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}访问信息:${NC}"
echo -e "  🌐 网站地址: http://$DOMAIN/"
echo -e "  🔧 管理后台: http://$DOMAIN/admin"
echo -e "  📡 API接口: http://$DOMAIN/api/menus"
echo -e "  🔑 默认账号: admin / 123456"
echo ""
echo -e "${YELLOW}⚠️  请立即修改默认密码！${NC}"
```

### 步骤2: 执行部署

```bash
# 给脚本执行权限
chmod +x deploy.sh

# 执行部署
./deploy.sh sv62 runx.sylu.net webhos-nav-item-complete.tar.gz
```

### 实际使用示例

```bash
# 成功部署到sv62的完整命令
./deploy.sh sv62 runx.sylu.net webhos-nav-item-complete.tar.gz

# 输出结果:
# ✅ HTTP访问正常 (200)
# 🌐 网站地址: http://runx.sylu.net/
# 🔧 管理后台: http://runx.sylu.net/admin
# 📡 API接口: http://runx.sylu.net/api/menus
# 🔑 默认账号: admin / 123456
```

## 🔧 故障排除

### 常见问题及解决方案

#### 1. 404 Not Found
```bash
# 检查.htaccess配置
ssh 服务器 "cat ~/domains/域名/public_html/.htaccess"

# 检查文件是否存在
ssh 服务器 "ls -la ~/domains/域名/public_html/app.js"

# 重启应用
ssh 服务器 "cd ~/domains/域名/public_html && touch tmp/restart.txt"
```

#### 2. 503 Service Unavailable
```bash
# 检查Node.js路径
ssh 服务器 "ls -la /opt/alt/alt-nodejs20/root/usr/bin/node"

# 检查应用启动
ssh 服务器 "cd ~/domains/域名/public_html && source /opt/alt/alt-nodejs20/enable && node app.js"
```

#### 3. 磁盘空间不足
```bash
# 检查空间使用
ssh 服务器 "du -sh ~/domains/域名/public_html/* | sort -hr"

# 清理不需要的文件
ssh 服务器 "cd ~/domains/域名/public_html && rm -f *.zip *.tar.gz && rm -rf web/node_modules"
```

#### 4. HTTPS访问问题
```bash
# 检查private_html配置
ssh 服务器 "ls -la ~/domains/域名/private_html"

# 如果private_html不存在，创建符号链接
ssh 服务器 "cd ~/domains/域名 && ln -sf public_html private_html"

# 注意: 某些服务器HTTPS配置需要服务商支持
# sv8测试: HTTP正常，HTTPS返回503 (服务器配置问题)
# sv62测试: HTTP正常，HTTPS需要进一步配置
```

## 📊 部署验证

### 功能测试清单

- [x] HTTP访问正常 (200 OK) - sv62测试通过
- [ ] HTTPS访问正常 (200 OK) - 需要服务器配置支持
- [x] 管理后台可访问 - sv62测试通过
- [x] API接口正常响应 - sv62测试通过
- [x] 默认账号可登录 - sv62测试通过
- [x] 密码修改功能正常 - sv62测试通过

### 性能测试

```bash
# 测试响应时间
curl -w "@curl-format.txt" -o /dev/null -s http://域名/

# 测试并发访问
ab -n 100 -c 10 http://域名/
```

## 🎯 最佳实践

### 部署前准备
1. **环境分析**: 先了解服务器配置和目录结构
2. **备份数据**: 备份现有文件（如果有）
3. **空间检查**: 确保有足够的磁盘空间 (至少50MB)
4. **权限确认**: 确认有SSH访问权限

### 部署过程
1. **使用完整版本**: 避免npm install问题，直接使用webhos-nav-item-complete.tar.gz
2. **正确配置路径**: .htaccess中的路径必须准确，特别是PassengerAppRoot
3. **选择合适版本**: 使用Node.js 20版本 (/opt/alt/alt-nodejs20/root/usr/bin/node)
4. **及时验证**: 部署后立即测试功能

### 部署后维护
1. **修改默认密码**: 提高安全性 (admin/123456)
2. **定期备份**: 备份应用数据
3. **监控日志**: 查看应用运行状态
4. **更新依赖**: 定期更新安全补丁

## 📝 经验总结

### 成功要素
- ✅ **平台分析**: 了解服务器环境配置 (sv62成功案例)
- ✅ **完整部署包**: 使用预构建的完整版本 (webhos-nav-item-complete.tar.gz)
- ✅ **正确配置**: .htaccess配置准确 (PassengerAppRoot路径)
- ✅ **目录结构**: 利用现有的目录结构 (public_html)
- ✅ **及时验证**: 部署后立即测试 (HTTP 200 OK)

### 避免的问题
- ❌ **npm install**: 在服务器上安装依赖容易失败 (磁盘配额、权限问题)
- ❌ **路径错误**: .htaccess中的路径不准确 (导致404错误)
- ❌ **版本不匹配**: Node.js版本选择错误 (使用Node.js 20)
- ❌ **权限问题**: 目录权限设置不正确
- ❌ **空间不足**: 磁盘空间不够 (至少需要50MB)

## 🎉 部署完成

按照以上方案，您的Node.js应用应该能够：
- ✅ HTTP正常访问 (sv62测试通过)
- ⚠️ HTTPS访问 (需要服务器配置支持)
- ✅ 所有功能正常工作
- ✅ 管理后台可正常使用
- ✅ API接口正常响应

**记得修改默认密码以提高安全性！**

---

**文档版本**: v2.1  
**创建时间**: 2025年10月22日  
**更新时间**: 2025年10月22日  
**适用平台**: webhostmost.com (CloudLinux + LiteSpeed + Passenger)  
**应用版本**: webhos-Nav-Item  
**测试服务器**: sv62 (成功), sv8 (HTTP成功)  
**GitHub仓库**: https://github.com/phaip88/webhos-Nav-Item