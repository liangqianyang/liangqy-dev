FROM elasticsearch:8.13.0

# 安装 IK 中文分词插件（版本需与 ES 一致）
# 国内备用镜像：https://get.infini.cloud/elasticsearch/analysis-ik/8.13.0
# GitHub 源：https://github.com/infinilabs/analysis-ik/releases/download/v8.13.0/elasticsearch-analysis-ik-8.13.0.zip
RUN elasticsearch-plugin install --batch \
    https://get.infini.cloud/elasticsearch/analysis-ik/8.13.0
