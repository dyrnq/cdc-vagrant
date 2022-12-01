# cdc-vagrant

## introduce

This project is for experiment of flink-cdc and doris.

CDC(Change Data Capture) is made up of two components, the CDD and the CDT. CDD is stand for Change Data Detection and CDT is stand for Change Data Transfer.

## architecture

| vm    | role                                                 | ip             | xxx_home       |
|-------|------------------------------------------------------|----------------|----------------|
| vm111 | doris FE(leader)                                     | 192.168.56.111 | /opt/doris/fe/ |
| vm112 | doris FE(observer)                                   | 192.168.56.112 | /opt/doris/fe/ |
| vm113 | doris BE                                             | 192.168.56.113 | /opt/doris/be/ |
| vm114 | doris BE                                             | 192.168.56.114 | /opt/doris/be/ |
| vm115 | doris BE                                             | 192.168.56.115 | /opt/doris/be/ |
| vm116 | hdfs: NameNode（active）,zkfc, yarn: RM ,zookeeper   | 192.168.56.116 |                |
| vm117 | hdfs: NameNode（standby）,zkfc, yarn: RM ,zookeeper  | 192.168.56.117 |                |
| vm118 | hdfs: NameNode（observer）,zkfc, yarn: RM ,zookeeper | 192.168.56.118 |                |
| vm119 | hdfs: DataNode, JournalNode, yarn: NM                | 192.168.56.119 |                |
| vm120 | hdfs: DataNode, JournalNode, yarn: NM                | 192.168.56.120 |                |
| vm121 | hdfs: DataNode, JournalNode, yarn: NM                | 192.168.56.121 |                |

## HDFS HA

```bash




# vm116
# hdfs namenode -format (执行一次)
# hdfs --daemon start namenode (依赖QJM，需启动 hdfs --daemon start journalnode)
# hdfs zkfc -formatZK (执行一次)
# hdfs --daemon start zkfc


# vm117
# hdfs namenode -bootstrapStandby （执行一次）
# hdfs --daemon start namenode (依赖QJM，需启动 hdfs --daemon start journalnode)
# hdfs --daemon start zkfc

# vm118
# hdfs namenode -bootstrapStandby （执行一次）
# hdfs --daemon start namenode (依赖QJM，需启动 hdfs --daemon start journalnode)
# hdfs --daemon start zkfc

# hduser@vm116:~$ hdfs haadmin -getServiceState nn1
# standby
# hduser@vm116:~$ hdfs haadmin -getServiceState nn2
# active
# hduser@vm116:~$ hdfs haadmin -getServiceState nn3
# standby


# vm119 vm120 vm121
# hdfs --daemon start journalnode
# hdfs --daemon start datanode
```

## YARN HA

```bash
# yarn --daemon start resourcemanager   //vm116 vm117 vm118
# yarn --daemon start nodemanager       //vm119 vm120 vm121
```

## ref

- [Deprecated Properties](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/DeprecatedProperties.html)
- [HDFS High Availability](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithNFS.html)
- [HDFS High Availability Using the Quorum Journal Manager](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HDFSHighAvailabilityWithQJM.html)
- [ResourceManager High Availability](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/ResourceManagerHA.html)
