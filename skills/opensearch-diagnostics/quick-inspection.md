# Quick Cluster Inspection

Fast triage: answer "Is this cluster healthy?" with 5 commands.

## The 5 Essential Commands

Run these sequentially. Stop and escalate to `deep-analysis-reference.md` if any check fails.

### 1. Cluster Health

```bash
curl -s "$PROTOCOL://$HOST:$PORT/_cluster/health?pretty"
```

| Metric | Healthy | Concerning |
|--------|---------|------------|
| `status` | `green` | `yellow` = missing replicas, `red` = missing primaries |
| `unassigned_shards` | 0 | > 0 means shards can't be allocated |
| `number_of_pending_tasks` | 0 | > 5 means cluster state updates are backing up |
| `active_shards_percent` | 100% | < 100% means data is at risk |

### 2. Node Resources

```bash
curl -s "$PROTOCOL://$HOST:$PORT/_cat/nodes?v&s=cpu:desc"
```

| Column | Healthy | Concerning |
|--------|---------|------------|
| `heap.percent` | < 75% | > 85% = GC pressure, OOM risk |
| `cpu` | < 80% | > 90% sustained = overloaded |
| `disk.used_percent` | < 80% | > 85% = watermark risk, > 90% = read-only indices |

### 3. Troubled Indices

```bash
curl -s "$PROTOCOL://$HOST:$PORT/_cat/indices?v&s=index&health=yellow,red"
```

Empty output = all indices green. Any rows here need investigation.

Check: `docs.count`, `store.size`, `pri` (primary shards), `rep` (replicas).

### 4. Unassigned Shards

```bash
curl -s "$PROTOCOL://$HOST:$PORT/_cat/shards?v&s=state&h=index,shard,prirep,state,unassigned.reason"
```

Only shows unassigned shards when sorted by state. Common reasons:
- `INDEX_CREATED` — new index, allocation in progress (transient)
- `CLUSTER_RECOVERED` — cluster restart, recovering (transient)
- `NODE_LEFT` — node departed, need another node or reduce replicas
- `ALLOCATION_FAILED` — disk full, corrupt shard, or allocation rules blocking

### 5. Thread Pool Pressure

```bash
curl -s "$PROTOCOL://$HOST:$PORT/_cat/thread_pool/search,write?v&h=node_name,name,active,queue,rejected"
```

| Column | Healthy | Concerning |
|--------|---------|------------|
| `queue` | 0 | > 0 means requests waiting |
| `rejected` | 0 | > 0 means requests dropped — clients see errors |

## Escalation Triggers

Switch to `deep-analysis-reference.md` when ANY of these are true:

- Cluster status is `yellow` or `red`
- Any node `heap.percent` > 85%
- Any `rejected` > 0 in thread pools
- Unassigned shards with non-transient reasons
- User reports slow queries or indexing
- User reports intermittent errors or timeouts
