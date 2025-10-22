# Node.js 应用部署完整指南

## 📋 项目概述

本文档提供了在webhostmost.com平台上部署Node.js应用的完整解决方案，包括构建模式和非构建模式两种部署方式。

## 🎯 部署目标

- **应用**: webhos-Nav-Item (Node.js导航应用)
- **平台**: webhostmost.com (CloudLinux + LiteSpeed + Passenger)
- **目标**: 实现HTTP和HTTPS双协议访问

## 📊 平台环境分析

### 标准环境配置
- **操作系统**: CloudLinux
- **Web服务器**: LiteSpeed + Passenger
- **Node.js版本**: 10, 11, 12, 14, 16, 18, 19, 20, 22
- **推荐版本**: Node.js 20
- **部署方式**: 传统Passenger配置

### 目录结构标准
```
~/domains/域名/
├── .htpasswd/          # 密码保护目录
├── private_html -> ./public_html  # HTTPS目录(符号链接)
├── public_html/        # HTTP目录
│   ├── cgi-bin/        # CGI脚本目录
│   └── [应用文件]      # 应用文件
└── tmp/               # 临时文件目录
```

## 🚀 方案一：构建模式部署（推荐）

### 适用场景
- 需要自定义构建配置
- 开发环境与生产环境不同
- 需要优化构建产物

### 步骤1: 本地构建

```bash
# 克隆项目
git clone https://github.com/phaip88/webhos-Nav-Item.git
cd webhos-Nav-Item

# 安装依赖
npm install

# 构建前端
cd web
npm install
npm run build

# 返回根目录
cd ..

# 安装生产依赖
npm install --production

# 创建完整部署包
tar -czf webhos-nav-item-complete.tar.gz \
  --exclude=node_modules/.cache \
  --exclude=web/node_modules \
  --exclude=web/src \
  --exclude=web/public \
  --exclude=*.log \
  --exclude=*.map \
  .
```

### 步骤2: 服务器部署

```bash
# 1. 分析平台环境
ssh 服务器 "pwd && whoami"
ssh 服务器 "ls -la ~/domains/"
ssh 服务器 "ls -la /opt/alt/alt-nodejs*/root/usr/bin/node"

# 2. 清理目标目录
ssh 服务器 "cd ~/domains/域名/public_html && rm -f index.html favicon.svg && rm -rf cgi-bin"

# 3. 上传部署包
scp webhos-nav-item-complete.tar.gz 服务器:~/

# 4. 解压到目标目录
ssh 服务器 "cd ~/domains/域名/public_html && tar -xzf ~/webhos-nav-item-complete.tar.gz"

# 5. 配置.htaccess
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

## 🚀 方案二：非构建模式部署（快速部署）

### 适用场景
- 快速部署测试
- 不需要自定义构建
- 使用预构建的完整版本

### 步骤1: 准备完整部署包

```bash
# 下载预构建的完整版本
wget https://github.com/phaip88/webhos-Nav-Item/releases/latest/download/webhos-nav-item-complete.tar.gz

# 或者使用已有的完整版本
# webhos-nav-item-complete.tar.gz (25MB)
```

### 步骤2: 一键部署脚本

创建部署脚本 `deploy.sh`:

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

### 步骤3: 执行部署

```bash
# 给脚本执行权限
chmod +x deploy.sh

# 执行部署
./deploy.sh sv62 runx.sylu.net webhos-nav-item-complete.tar.gz
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
```

## 📊 部署验证

### 功能测试清单

- [ ] HTTP访问正常 (200 OK)
- [ ] HTTPS访问正常 (200 OK)
- [ ] 管理后台可访问
- [ ] API接口正常响应
- [ ] 默认账号可登录
- [ ] 密码修改功能正常

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
3. **空间检查**: 确保有足够的磁盘空间
4. **权限确认**: 确认有SSH访问权限

### 部署过程
1. **使用完整版本**: 避免npm install问题
2. **正确配置路径**: .htaccess中的路径必须准确
3. **选择合适版本**: 使用Node.js 20版本
4. **及时验证**: 部署后立即测试功能

### 部署后维护
1. **修改默认密码**: 提高安全性
2. **定期备份**: 备份应用数据
3. **监控日志**: 查看应用运行状态
4. **更新依赖**: 定期更新安全补丁

## 📝 经验总结

### 成功要素
- ✅ **平台分析**: 了解服务器环境配置
- ✅ **完整部署包**: 使用预构建的完整版本
- ✅ **正确配置**: .htaccess配置准确
- ✅ **目录结构**: 利用现有的目录结构
- ✅ **及时验证**: 部署后立即测试

### 避免的问题
- ❌ **npm install**: 在服务器上安装依赖容易失败
- ❌ **路径错误**: .htaccess中的路径不准确
- ❌ **版本不匹配**: Node.js版本选择错误
- ❌ **权限问题**: 目录权限设置不正确
- ❌ **空间不足**: 磁盘空间不够

## 🎉 部署完成

按照以上方案，您的Node.js应用应该能够：
- ✅ HTTP和HTTPS正常访问
- ✅ 所有功能正常工作
- ✅ 管理后台可正常使用
- ✅ API接口正常响应

**记得修改默认密码以提高安全性！**

---

**文档版本**: v2.0  
**创建时间**: 2025年10月22日  
**适用平台**: webhostmost.com (CloudLinux + LiteSpeed + Passenger)  
**应用版本**: webhos-Nav-Item