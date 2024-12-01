# cdc-vagrant

<!-- TOC -->

- [cdc-vagrant](#cdc-vagrant)
  - [introduce](#introduce)
  - [architecture](#architecture)
    - [zookeeper cluster](#zookeeper-cluster)
    - [flink cluster](#flink-cluster)
    - [flink cdc](#flink-cdc)
    - [flink-cdc version matrix](#flink-cdc-version-matrix)
  - [ref](#ref)

<!-- /TOC -->

## introduce

This project is for experiment of flink-cdc and doris.

CDC(Change Data Capture) is made up of two components, the CDD and the CDT. CDD is stand for Change Data Detection and CDT is stand for Change Data Transfer.

Extract, Load, Transform (ELT) is a data integration process for transferring raw data from a source server to a data system (such as a data warehouse or data lake) on a target server and then preparing the information for downstream uses.

Streaming ETL (Extract, Transform, Load) is the processing and movement of real-time data from one place to another. ETL is short for the database functions extract, transform, and load.

## architecture

### zookeeper cluster

| vm    | role      | ip             | xxx_home       |
|-------|-----------|----------------|----------------|
| vm116 | zookeeper | 192.168.56.116 | /opt/zookeeper |
| vm117 | zookeeper | 192.168.56.117 | /opt/zookeeper |
| vm118 | zookeeper | 192.168.56.118 | /opt/zookeeper |

```bash
cd /opt/zookeeper
./bin/zkServer.sh status
```

```bash
echo stat | nc 127.0.0.1 2181
Zookeeper version: 3.8.4-9316c2a7a97e1666d8f4593f34dd6fc36ecc436c, built on 2024-02-12 22:16 UTC
Clients:
 /127.0.0.1:39370[0](queued=0,recved=1,sent=0)

Latency min/avg/max: 0/6.375/41
Received: 10
Sent: 9
Connections: 1
Outstanding: 0
Zxid: 0x100000003
Mode: follower
Node count: 5
```



### flink cluster

| vm    | role   | ip             | xxx_home   |
|-------|--------|----------------|------------|
| vm116 | minio  | 192.168.56.116 | /opt/minio |
| vm117 | minio  | 192.168.56.117 | /opt/minio |
| vm118 | minio  | 192.168.56.118 | /opt/minio |
| vm119 | minio  | 192.168.56.119 | /opt/minio |

| vm    | role                             | ip             | xxx_home   |
|-------|----------------------------------|----------------|------------|
| vm116 | sidekick, flink(masters+workers) | 192.168.56.116 | /opt/flink |
| vm117 | sidekick, flink(masters+workers) | 192.168.56.117 | /opt/flink |
| vm118 | sidekick, flink(masters+workers) | 192.168.56.118 | /opt/flink |
| vm119 | sidekick, flink(workers)         | 192.168.56.119 | /opt/flink |

> ssh init

```bash
vagrant ssh vm116
## vm116 vm117 vm118 vm119 四台分别执行
su -l root
bash /vagrant/scripts/ssh-copy-id.sh --iface enp0s8 --ips "192.168.56.116,192.168.56.117,192.168.56.118,192.168.56.119"
```

> minio init

```bash
vagrant ssh vm116
## 只需要在vm116上执行，且执行一次即可
curl -o /usr/local/bin/mc -# -fSL https://files.m.daocloud.io/dl.min.io/client/mc/release/linux-amd64/mc
chmod +x /usr/local/bin/mc

mc alias set myminio http://localhost:9000 minioadmin minioadmin
mc admin user svcacct add --access-key "u5SybesIDVX9b6Pk" --secret-key "lOpH1v7kdM6H8NkPu1H2R6gLc9jcsmWM" myminio minioadmin
# mc admin user svcacct add --access-key "myuserserviceaccount" --secret-key "myuserserviceaccountpassword" myminio minioadmin

mc mb myminio/flink
mc mb myminio/flink-state
```

```bash
## flink集群启动
su -l hduser
cd /opt/flink

## start-cluster
bin/start-cluster.sh
## stop-cluster
bin/stop-cluster.sh
## 测试一下
bin/flink run /opt/flink/examples/streaming/WordCount.jar
```

### flink cdc

vagrant ssh vm211

```bash
cd /vagrant/doris
docker compose exec doris-fe mysql -uroot -P9030 -h127.0.0.1 -e "show backends; show frontends;"
```

```bash
vagrant ssh vm116

flink_cdc_home="/opt/flink-cdc"
pushd $flink_cdc_home || exit 1
./bin/flink-cdc.sh /vagrant/doris/mysql-to-doris.yaml --jar lib/mysql-connector-java-8.0.27.jar --flink-home /opt/flink
popd || exit 1

```

### fink-sql-client

```bash
bin/sql-client.sh
SET execution.checkpointing.interval = 6000;

```

### flink-cdc version matrix

see <https://nightlies.apache.org/flink/flink-cdc-docs-master/docs/connectors/flink-sources/overview/#supported-flink-versions>

## ref

- [Deprecated Properties](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/DeprecatedProperties.html)
- [HDFS High Availability](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithNFS.html)
- [HDFS High Availability Using the Quorum Journal Manager](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html)
- [ResourceManager High Availability](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html)
- [High Performance HTTP Sidecar Load Balancer](https://github.com/minio/sidekick)
- [https://github.com/apache/doris/tree/master/samples/doris-demo](https://github.com/apache/doris/tree/master/samples/doris-demo)
- [Streaming ELT from MySQL to Doris](https://nightlies.apache.org/flink/flink-cdc-docs-release-3.2/docs/get-started/quickstart/mysql-to-doris/)
