# Sharding and Replication

**Purpose**: Guide for database scaling strategies: sharding and replication

## REPLICATION

### What is Replication?
- **Definition**: Copying data from primary to replica databases
- **Purpose**: High availability, read scaling, disaster recovery
- **Types**: Master-Slave (Primary-Replica), Master-Master, Multi-Primary

### PostgreSQL Replication

#### Streaming Replication (Primary-Replica)
```sql
-- Primary (postgresql.conf)
wal_level = replica
max_wal_senders = 5
wal_keep_segments = 100

-- Create replication user
CREATE USER replicator WITH REPLICATION PASSWORD 'password';
ALTER USER replicator WITH PASSWORD 'new_password';

-- pg_hba.conf (on replica)
host replication replicator <primary_ip>/32 md5

-- Create base backup on replica
pg_basebackup -h <primary_host> -D /var/lib/postgresql/data -U replicator -P -W -R -X stream -S slot1
```

#### Logical Replication
```sql
-- Primary (postgresql.conf)
wal_level = logical
max_replication_slots = 10

-- Create publication
CREATE PUBLICATION my_publication FOR TABLE users, posts;

-- Replica
CREATE SUBSCRIPTION my_subscription
CONNECTION 'host=primary dbname=mydb user=repuser password=password'
PUBLICATION my_publication;
```

### MySQL Replication

#### Binary Log Replication (Primary-Replica)
```sql
-- Primary (my.cnf)
[mysqld]
log-bin=mysql-bin
binlog-format=ROW
server-id=1

-- Create replication user
CREATE USER 'repl'@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';

-- Get master status
SHOW MASTER STATUS;

-- Replica (my.cnf)
[mysqld]
server-id=2
relay-log=relay-bin
read-only=1

-- Start replication
CHANGE MASTER TO
  MASTER_HOST='primary_host',
  MASTER_USER='repl',
  MASTER_PASSWORD='password',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=154;
START SLAVE;
```

### MongoDB Replication

#### Replica Set
```javascript
// Start primary
mongod --replSet myReplicaSet --port 27017 --dbpath /data/db1

// Start replicas
mongod --replSet myReplicaSet --port 27018 --dbpath /data/db2
mongod --replSet myReplicaSet --port 27019 --dbpath /data/db3

// Initialize replica set
rs.initiate({
  _id: "myReplicaSet",
  members: [
    { _id: 0, host: "localhost:27017" },
    { _id: 1, host: "localhost:27018" },
    { _id: 2, host: "localhost:27019", arbiterOnly: true }
  ]
});

// Check status
rs.status();
```

## SHARDING

### What is Sharding?
- **Definition**: Distributing data across multiple databases
- **Purpose**: Horizontal scaling (scale out), load distribution
- **Types**: Hash sharding, Range sharding, Directory-based sharding

### PostgreSQL Sharding

#### Using Citus (PostgreSQL Extension)
```sql
-- Install Citus
CREATE EXTENSION citus;

-- Create distributed table
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255),
  name VARCHAR(255)
);

-- Distribute table by hash
SELECT create_distributed_table('users', 'id');

-- Or distribute by range
SELECT create_distributed_table('logs', 'created_at', 'range');
```

#### Manual Sharding
```sql
-- Shard 1 (US East)
CREATE TABLE users_east (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255),
  name VARCHAR(255),
  region VARCHAR(10) CHECK (region = 'east')
);

-- Shard 2 (US West)
CREATE TABLE users_west (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255),
  name VARCHAR(255),
  region VARCHAR(10) CHECK (region = 'west')
);

-- Application routes based on region
-- Example: userId % 2 determines shard
```

### MySQL Sharding

#### Using ProxySQL
```bash
# Install ProxySQL
apt-get install proxysql

# Configure shards (config file)
[servers]
host1 = 127.0.0.1:3306
host2 = 127.0.0.1:3307

# Configure sharding rules
[mysql_variables]
mysql-sharding = 1

# Configure shard mapping
[proxysql_query_rules]
shard_id = 0
shard_key = user_id
shard_map = users_east,users_west
```

#### Manual Sharding
```sql
-- Shard 1 (users_0)
CREATE TABLE users_0 (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT,
  email VARCHAR(255),
  shard_id INT CHECK (shard_id = 0)
);

-- Shard 2 (users_1)
CREATE TABLE users_1 (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT,
  email VARCHAR(255),
  shard_id INT CHECK (shard_id = 1)
);

-- Application routes: shard_id = user_id % 2
```

### MongoDB Sharding

#### Sharded Cluster Setup
```javascript
// 1. Start config servers (3 for HA)
mongod --configsvr --port 27019 --dbpath /data/config1
mongod --configsvr --port 27020 --dbpath /data/config2
mongod --configsvr --port 27021 --dbpath /data/config3

// 2. Start mongos (query router)
mongos --configdb localhost:27019,localhost:27020,localhost:27021

// 3. Start shard replica sets (replica sets for each shard)
// See MongoDB replication section above

// 4. Add shards to cluster
sh.addShard("shard1/localhost:27017")
sh.addShard("shard2/localhost:27018")

// 5. Enable sharding on database
sh.enableSharding("mydb")

// 6. Shard collection (hashed shard key)
sh.shardCollection("mydb.users", { _id: "hashed" })

// Or range sharding
sh.shardCollection("mydb.logs", { timestamp: 1 })

// Check sharding status
sh.status()
```

#### Shard Key Selection
```javascript
// Good: High cardinality, even distribution
// Hashed shard key (recommended)
sh.shardCollection("mydb.users", { _id: "hashed" })

// Ranged shard key (good for range queries)
sh.shardCollection("mydb.logs", { timestamp: 1 })

// Bad: Low cardinality
sh.shardCollection("mydb.users", { country: 1 }) // Uneven distribution

// Bad: Hotspot (one user has many records)
sh.shardCollection("mydb.orders", { user_id: 1 }) // Uneven distribution
```

## REPLICATION VS SHARDING

### When to Use Replication
- **Read Scaling**: Many reads, few writes
- **High Availability**: Need failover capability
- **Data Redundancy**: Need backup copies
- **Geographic Distribution**: Replicas in different regions

### When to Use Sharding
- **Write Scaling**: Too many writes for single database
- **Data Volume**: Data exceeds single database capacity
- **Query Performance**: Dataset too large for single server
- **Cost**: Cheaper to scale horizontally than vertically

### Hybrid Approach
```sql
-- Replication + Sharding
-- Shard: Distribute data across multiple database clusters
-- Replicate: Each shard has replicas for HA and read scaling

-- Example Architecture:
-- Shard 1 (Primary + 2 Replicas)
-- Shard 2 (Primary + 2 Replicas)
-- Shard 3 (Primary + 2 Replicas)
```

## SCALING STRATEGIES

### Vertical Scaling (Scale Up)
- **Definition**: Increase server resources (CPU, RAM, SSD)
- **Pros**: Simple, no application changes
- **Cons**: Limited by hardware, expensive, single point of failure

### Horizontal Scaling (Scale Out)
- **Definition**: Add more servers
- **Pros**: Unlimited scaling, cost-effective, high availability
- **Cons**: Complex, requires application changes, eventual consistency

### Scaling Patterns

#### Read Replicas
```python
# Application routes reads to replicas
# Writes go to primary

from django.db import connections

def get_read_connection():
    # Return replica connection
    return connections['read_replica']

def get_write_connection():
    # Return primary connection
    return connections['default']

# Read operation (uses replica)
User.objects.using('read_replica').filter(active=True)

# Write operation (uses primary)
User.objects.using('default').create(name='John')
```

#### Write Splitting
```python
# Split writes across shards based on shard key

def get_shard(user_id):
    shard_id = user_id % NUM_SHARDS
    return connections[f'shard_{shard_id}']

def create_user(name, email):
    user_id = generate_user_id()
    shard = get_shard(user_id)
    User.objects.using(shard.alias).create(
        id=user_id,
        name=name,
        email=email
    )
```

#### Consistent Hashing
```python
# Distribute keys across shards evenly
# Minimize data movement when shards added/removed

import hashlib

def consistent_hash(key, num_shards):
    # Hash key and map to shard
    hash_value = int(hashlib.md5(key.encode()).hexdigest(), 16)
    return hash_value % num_shards

def get_shard_for_key(key, num_shards):
    return consistent_hash(key, num_shards)

# Example
shard = get_shard_for_key('user:123', 10)  # Returns shard 0-9
```

## FAILOVER STRATEGIES

### Automatic Failover
```sql
-- PostgreSQL: Patroni for automatic failover
-- MySQL: Orchestrator for automatic failover
-- MongoDB: Automatic replica set failover

-- Example: Patroni configuration
scope: pg-cluster
name: postgresql0

restapi:
  listen: 0.0.0.0:8008
  connect_address: 192.168.1.1:8008

postgresql:
  listen: 0.0.0.0:5432
  data_dir: /var/lib/postgresql/data
  replication:
    username: replicator
    password: password
    network: 192.168.1.0/24

tags:
    nofailover: false
    noloadbalance: false
```

### Manual Failover
```sql
-- PostgreSQL: Promote replica to primary
pg_ctl promote -D /var/lib/postgresql/data

-- MySQL: Stop replica, promote to primary
STOP SLAVE;
RESET SLAVE ALL;

-- MongoDB: Step down primary
rs.stepDown(600)  # Step down for 600 seconds
```

## BEST PRACTICES

### Replication Best Practices
- **Monitor Lag**: Monitor replication lag (seconds/minutes behind)
- **Network Security**: Encrypt replication traffic
- **Authentication**: Use strong authentication for replication
- **Monitoring**: Set up alerts for replica failures
- **Capacity Planning**: Plan for replica capacity based on read load

### Sharding Best Practices
- **Choose Good Shard Key**: High cardinality, even distribution
- **Avoid Hotspots**: Don't shard on frequently accessed small set
- **Plan for Growth**: Plan for adding/removing shards
- **Data Rebalancing**: Plan for rebalancing when shards added
- **Monitoring**: Monitor shard health, data distribution

### Consistency Models
- **Strong Consistency**: Replication (reads from primary after writes)
- **Eventual Consistency**: Sharding (reads may be stale)
- **Read Your Writes**: Route user to same shard
- **Session Affinity**: Route session to same replica

### Disaster Recovery
- **Backups**: Backup from replicas (primary replicas to backup)
- **Point-in-Time Recovery**: Use binary logs/WAL for recovery
- **Off-site Backups**: Store backups in different region/availability zone
- **Test Recovery**: Regularly test recovery procedures
