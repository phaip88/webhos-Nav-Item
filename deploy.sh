#!/bin/bash

# Node.js 应用一键部署脚本
# 适用于 webhostmost.com 平台

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
