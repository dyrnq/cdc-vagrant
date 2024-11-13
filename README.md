# cdc-vagrant

## introduce

This project is for experiment of flink-cdc and doris.

CDC(Change Data Capture) is made up of two components, the CDD and the CDT. CDD is stand for Change Data Detection and CDT is stand for Change Data Transfer.

Extract, Load, Transform (ELT) is a data integration process for transferring raw data from a source server to a data system (such as a data warehouse or data lake) on a target server and then preparing the information for downstream uses.

Streaming ETL (Extract, Transform, Load) is the processing and movement of real-time data from one place to another. ETL is short for the database functions extract, transform, and load.

<!--ts-->
- [cdc-vagrant](#cdc-vagrant)
  - [introduce](#introduce)
  - [architecture](#architecture)
    - [doris cluster](#doris-cluster)
    - [hdfs cluster and yarn cluster](#hdfs-cluster-and-yarn-cluster)
    - [flink standalone cluster](#flink-standalone-cluster)
  - [Usage](#usage)
    - [HDFS HA](#hdfs-ha)
    - [YARN HA](#yarn-ha)
    - [minio HA](#minio-ha)
      - [minio server](#minio-server)
      - [minio client](#minio-client)
      - [minio load balancer](#minio-load-balancer)
    - [flink standalone HA](#flink-standalone-ha)
    - [flink cdc](#flink-cdc)
      - [mysql](#mysql)
      - [postgres](#postgres)
      - [cdc to es](#cdc-to-es)
      - [mysql additional test](#mysql-additional-test)
      - [cdc to doris](#cdc-to-doris)
  - [ref](#ref)
<!--te-->

## architecture

### zookeeper cluster

| vm    | role      | ip             | xxx_home       |
|-------|-----------|----------------|----------------|
| vm101 | zookeeper | 192.168.56.101 | /opt/zookeeper |
| vm102 | zookeeper | 192.168.56.102 | /opt/zookeeper |
| vm103 | zookeeper | 192.168.56.103 | /opt/zookeeper |

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

### doris cluster

| vm    | role                                               | ip             | xxx_home       |
|-------|----------------------------------------------------|----------------|----------------|
| vm111 | doris FE(leader)                                   | 192.168.56.111 | /opt/doris/fe/ |
| vm112 | doris FE(observer)                                 | 192.168.56.112 | /opt/doris/fe/ |
| vm113 | doris BE                                           | 192.168.56.113 | /opt/doris/be/ |
| vm114 | doris BE                                           | 192.168.56.114 | /opt/doris/be/ |
| vm115 | doris BE                                           | 192.168.56.115 | /opt/doris/be/ |

### HDFS cluster and YARN cluster

| vm    | role                                 | ip             | xxx_home    |
|-------|--------------------------------------|----------------|-------------|
| vm116 | NameNode(active),zkfc, JournalNode   | 192.168.56.116 | /opt/hadoop |
| vm117 | NameNode(standby),zkfc, JournalNode  | 192.168.56.117 | /opt/hadoop |
| vm118 | NameNode(observer),zkfc, JournalNode | 192.168.56.118 | /opt/hadoop |
| vm119 | DataNode                             | 192.168.56.119 | /opt/hadoop |
| vm120 | DataNode                             | 192.168.56.120 | /opt/hadoop |
| vm121 | DataNode                             | 192.168.56.121 | /opt/hadoop |


| vm    | role     | ip             | xxx_home    |
|-------|----------|----------------|-------------|
| vm116 | yarn: RM | 192.168.56.116 | /opt/hadoop |
| vm117 | yarn: RM | 192.168.56.117 | /opt/hadoop |
| vm118 | yarn: RM | 192.168.56.118 | /opt/hadoop |
| vm119 | yarn: NM | 192.168.56.119 | /opt/hadoop |
| vm120 | yarn: NM | 192.168.56.120 | /opt/hadoop |
| vm121 | yarn: NM | 192.168.56.121 | /opt/hadoop |

```bash
###########################################################
# 以下所有操作都需要在hduser用户下执行
# su -l hduser
###########################################################
# vm116
# hdfs --daemon start journalnode
# hdfs namenode -format (执行一次)
# hdfs zkfc -formatZK (执行一次)
# hdfs --daemon start namenode && hdfs --daemon start zkfc



# vm117 vm118
# hdfs --daemon start journalnode
# hdfs namenode -bootstrapStandby （执行一次）
# hdfs --daemon start namenode && hdfs --daemon start zkfc


## test hdfs HA
(
hdfs haadmin -getServiceState nn1
hdfs haadmin -getServiceState nn2
hdfs haadmin -getServiceState nn3
)

active
standby
standby


# vm119 vm120 vm121
# hdfs --daemon start datanode
```

```bash
# yarn --daemon start resourcemanager   //vm116 vm117 vm118
# yarn --daemon start nodemanager       //vm119 vm120 vm121
```

### flink standalone cluster

minio cluster and flink standalone cluster

Reuse the above virtual machines due to hardware constraints.

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
| vm120 | sidekick, flink(workers)         | 192.168.56.120 | /opt/flink |
| vm121 | sidekick, flink(workers)         | 192.168.56.121 | /opt/flink |


> minio client

```bash
curl -o /usr/local/bin/mc -# -fSL https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x /usr/local/bin/mc
mc --help
```

```bash
mc alias set myminio http://localhost:9000 minioadmin minioadmin
mc admin user svcacct add --access-key "u5SybesIDVX9b6Pk" --secret-key "lOpH1v7kdM6H8NkPu1H2R6gLc9jcsmWM" myminio minioadmin
# mc admin user svcacct add --access-key "myuserserviceaccount" --secret-key "myuserserviceaccountpassword" myminio minioadmin
```

[mc](https://github.com/minio/mc)

> minio load balancer

```bash
bash /vagrant/scripts/install-minio-sidekick.sh --port "18000" --sites "http://vm{116...119}:9000"
```

```bash
mc mb myminio/flink
mc mb myminio/flink-state
```


```bash
# vm116 vm117 vm118 vm119 vm120 vm121
bash /vagrant/scripts/install-flink.sh
# https://blog.csdn.net/hiliang521/article/details/126860098

su -l hduser
cd /opt/flink

## start-cluster
bin/start-cluster.sh
## stop-cluster
bin/stop-cluster.sh



bin/flink run /opt/flink/examples/streaming/WordCount.jar
```

## Usage

### flink cdc

this is an experimental environment of [基于 Flink CDC 构建 MySQL 和 Postgres 的 Streaming ETL](https://nightlies.apache.org/flink/flink-cdc-docs-release-3.2/docs/get-started/quickstart/mysql-to-doris/).

The difference is that high availability of flink standalone and Shanghai time zone is used.

#### mysql

```bash
docker compose exec mysql mysql -uroot -p123456
```

```bash
SET GLOBAL time_zone = '+8:00';
flush privileges;
SHOW VARIABLES LIKE '%time_zone%';
-- MySQL
CREATE DATABASE mydb;
USE mydb;
CREATE TABLE products (
  id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description VARCHAR(512)
);
ALTER TABLE products AUTO_INCREMENT = 101;
INSERT INTO products
VALUES (default,"scooter","Small 2-wheel scooter"),
       (default,"car battery","12V car battery"),
       (default,"12-pack drill bits","12-pack of drill bits with sizes ranging from #40 to #3"),
       (default,"hammer","12oz carpenter's hammer"),
       (default,"hammer","14oz carpenter's hammer"),
       (default,"hammer","16oz carpenter's hammer"),
       (default,"rocks","box of assorted rocks"),
       (default,"jacket","water resistent black wind breaker"),
       (default,"spare tire","24 inch spare tire");

CREATE TABLE orders (
  order_id INTEGER NOT NULL AUTO_INCREMENT PRIMARY KEY,
  order_date DATETIME NOT NULL,
  customer_name VARCHAR(255) NOT NULL,
  price DECIMAL(10, 5) NOT NULL,
  product_id INTEGER NOT NULL,
  order_status BOOLEAN NOT NULL -- Whether order has been placed
) AUTO_INCREMENT = 10001;

INSERT INTO orders
VALUES (default, '2020-07-30 10:08:22', 'Jark', 50.50, 102, false),
       (default, '2020-07-30 10:11:09', 'Sally', 15.00, 105, false),
       (default, '2020-07-30 12:00:30', 'Edward', 25.25, 106, false);

```

#### postgres

```bash
docker compose exec postgres psql -h localhost -U postgres
```

```bash

CREATE TABLE shipments (
  shipment_id SERIAL NOT NULL PRIMARY KEY,
  order_id SERIAL NOT NULL,
  origin VARCHAR(255) NOT NULL,
  destination VARCHAR(255) NOT NULL,
  is_arrived BOOLEAN NOT NULL
);
ALTER SEQUENCE public.shipments_shipment_id_seq RESTART WITH 1001;
ALTER TABLE public.shipments REPLICA IDENTITY FULL;
INSERT INTO shipments
VALUES (default,10001,'Beijing','Shanghai',false),
       (default,10002,'Hangzhou','Shanghai',false),
       (default,10003,'Shanghai','Hangzhou',false);
```

#### cdc to es

sql-client.sh

enable checkpoints every 3 seconds.

```bash
SET execution.checkpointing.interval = 3s;
```

```bash

CREATE TABLE products (
    id INT,
    name STRING,
    description STRING,
    PRIMARY KEY (id) NOT ENFORCED
  ) WITH (
    'connector' = 'mysql-cdc',
    'hostname' = '192.168.56.116',
    'port' = '3306',
    'username' = 'root',
    'password' = '123456',
    'database-name' = 'mydb',
    'table-name' = 'products'
  );

CREATE TABLE orders (
   order_id INT,
   order_date TIMESTAMP(0),
   customer_name STRING,
   price DECIMAL(10, 5),
   product_id INT,
   order_status BOOLEAN,
   PRIMARY KEY (order_id) NOT ENFORCED
 ) WITH (
   'connector' = 'mysql-cdc',
   'hostname' = '192.168.56.116',
   'port' = '3306',
   'username' = 'root',
   'password' = '123456',
   'database-name' = 'mydb',
   'table-name' = 'orders'
 );

CREATE TABLE shipments (
   shipment_id INT,
   order_id INT,
   origin STRING,
   destination STRING,
   is_arrived BOOLEAN,
   PRIMARY KEY (shipment_id) NOT ENFORCED
 ) WITH (
   'connector' = 'postgres-cdc',
   'hostname' = '192.168.56.116',
   'port' = '5432',
   'username' = 'postgres',
   'password' = 'postgres',
   'database-name' = 'postgres',
   'schema-name' = 'public',
   'table-name' = 'shipments'
 );


 CREATE TABLE enriched_orders (
   order_id INT,
   order_date TIMESTAMP(0),
   customer_name STRING,
   price DECIMAL(10, 5),
   product_id INT,
   order_status BOOLEAN,
   product_name STRING,
   product_description STRING,
   shipment_id INT,
   origin STRING,
   destination STRING,
   is_arrived BOOLEAN,
   PRIMARY KEY (order_id) NOT ENFORCED
 ) WITH (
     'connector' = 'elasticsearch-7',
     'hosts' = 'http://192.168.56.116:9200',
     'index' = 'enriched_orders'
 );

 INSERT INTO enriched_orders
 SELECT o.*, p.name, p.description, s.shipment_id, s.origin, s.destination, s.is_arrived
 FROM orders AS o
 LEFT JOIN products AS p ON o.product_id = p.id
 LEFT JOIN shipments AS s ON o.order_id = s.order_id;


```

Principle explanation

create source tables that capture the change data from the corresponding database tables.
create slink table that is used to load data to the Elasticsearch.
select source table into slink talbe to write to the Elasticsearch.

#### mysql additional test

```bash
INSERT INTO orders VALUES (default, '2022-07-30 10:08:22', 'dddd', 666, 105, false);
INSERT INTO orders VALUES (default, '2022-07-30 10:08:22', 'tttt', 888, 105, false);
```

#### cdc to doris

create doris database

```bash
mysql  -h 192.168.56.111 -P9030 -uroot
CREATE DATABASE IF NOT EXISTS db;


CREATE TABLE db.`test_sink` (
  `id` INT,
  `name` STRING
) ENGINE=OLAP COMMENT "OLAP" 
DISTRIBUTED BY HASH(`id`) BUCKETS 3;

```

sql-client.sh

enable checkpoints every 3 seconds.

```bash
SET execution.checkpointing.interval = 3s;
```

```bash

CREATE TABLE cdc_test_source (
    id INT,
    name STRING,
    description STRING,
    PRIMARY KEY (id) NOT ENFORCED
  ) WITH (
    'connector' = 'mysql-cdc',
    'hostname' = '192.168.56.116',
    'port' = '3306',
    'username' = 'root',
    'password' = '123456',
    'database-name' = 'mydb',
    'table-name' = 'products'
  );



CREATE TABLE doris_test_sink (
id INT,
name STRING
) WITH (
  'connector' = 'doris',
  'fenodes' = '192.168.56.111:8030',
  'table.identifier' = 'db.test_sink',
  'username' = 'root',
  'password' = '',
  'sink.label-prefix' = 'doris_label',
  'sink.properties.format' = 'json',
  'sink.properties.read_json_by_line' = 'true'
);

INSERT INTO doris_test_sink select id,name from cdc_test_source;

```

[https://github.com/apache/doris/blob/master/samples/doris-demo/flink-demo-v1.1](https://github.com/apache/doris/blob/master/samples/doris-demo/flink-demo-v1.1/src/main/java/org/apache/doris/demo/flink/Cdc2DorisSQLDemo.java)

## ref

- [Deprecated Properties](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/DeprecatedProperties.html)
- [HDFS High Availability](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithNFS.html)
- [HDFS High Availability Using the Quorum Journal Manager](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html)
- [ResourceManager High Availability](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html)
- [High Performance HTTP Sidecar Load Balancer](https://github.com/minio/sidekick)