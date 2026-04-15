# Deep Analysis Reference

Comprehensive diagnostic reference for OpenSearch/Elasticsearch clusters. Use this when the quick inspection found problems, or when analyzing an offline stats dump.

## Cluster-Level Diagnostics

### `_cluster/health`
**What:** Overall cluster status — the single most important check.
**Why:** Red means primary shards missing (data loss risk). Yellow means replica shards missing (reduced redundancy).
**Key fields:** `status`, `unassigned_shards`, `number_of_pending_tasks`, `active_shards_percent_as_number`

### `_cluster/stats`
**What:** Aggregated resource usage across all nodes.
**Why:** Shows total shard count, memory, disk, and index count. Helps identify cluster-wide resource exhaustion.
**Key fields:** `indices.shards.total` (> 1000/node is concerning), `nodes.jvm.mem`, `nodes.fs`

### `_cluster/settings?include_defaults=true`
**What:** All cluster settings including defaults.
**Why:** Reveals watermark thresholds, recovery throttling, and allocation rules that may block shard assignment.
**Key fields:**
- `cluster.routing.allocation.disk.watermark.low/high/flood_stage`
- `cluster.routing.allocation.total_shards_per_node`
- `indices.recovery.max_bytes_per_sec`

### `_cluster/pending_tasks`
**What:** Queued cluster state updates.
**Why:** A growing queue means the master node is overloaded — common with too many indices/shards or frequent mapping changes.
**Concerning:** Any task with `time_in_queue_millis` > 30000

## Node-Level Diagnostics

### `_nodes/stats`
**What:** Per-node resource usage — the deepest node-level view.
**Why:** Reveals JVM heap, GC behavior, circuit breaker state, and I/O metrics per node.
**Key fields:**
- `jvm.mem.heap_used_percent` — > 85% is danger zone
- `jvm.gc.collectors.old.collection_time_in_millis` — long old GC pauses mean heap pressure
- `breakers.parent.tripped` — > 0 means requests were rejected to prevent OOM
- `breakers.fielddata.tripped` — fielddata queries causing memory spikes
- `fs.total.available_in_bytes` — disk space remaining
- `thread_pool.search.rejected` / `thread_pool.write.rejected` — dropped requests

### `_nodes/hot_threads?threads=10`
**What:** Stack traces of CPU-intensive threads.
**Why:** Identifies what's consuming CPU — specific queries, merges, or GC.
**Interpretation:** Same thread appearing repeatedly = stuck operation. Many threads in `search` = query overload. Threads in `merge` = heavy indexing with segment merging.

### `_cat/nodes?v`
**What:** One-line-per-node summary.
**Why:** Quick comparison across nodes — spot the outlier.
**Watch for:** One node with much higher heap/cpu/disk than others = unbalanced cluster.

## Index-Level Diagnostics

### `{index}/_stats`
**What:** Per-index performance counters.
**Why:** Shows search/indexing rates, latency, refresh time, merge activity.
**Key fields:**
- `search.query_time_in_millis` / `search.query_total` = avg query latency
- `indexing.index_time_in_millis` / `indexing.index_total` = avg indexing latency
- `refresh.total_time_in_millis` — high refresh time slows searches
- `merges.current` — active merges consume I/O and CPU

### `{index}/_settings?include_defaults=true`
**What:** Index configuration with all defaults exposed.
**Why:** Reveals misconfiguration — wrong replica count, disabled refresh, inappropriate merge policy.
**Key fields:**
- `number_of_replicas` — 0 in production = no redundancy
- `refresh_interval` — `-1` means disabled (data not searchable until manual refresh)
- `merge.policy` — TieredMergePolicy settings affect segment count
- `translog.durability` — `async` trades safety for speed

### `{index}/_segments`
**What:** Per-shard segment details including memory usage.
**Why:** Too many segments = slow searches, high memory. Segments are immutable — old deleted docs waste space.
**Concerning:** > 50 segments per shard needs `_forcemerge`. High `memory_in_bytes` in segments = field data or points overhead.

### `{index}/_mapping`
**What:** Field types, analyzers, and mapping structure.
**Why:** Mapping explosions (too many fields) cause heap pressure and slow cluster state updates. Wrong field types cause poor query performance.
**Concerning:** > 1000 fields, deeply nested objects, `text` fields without `keyword` sub-field (or vice versa).

## Additional Diagnostic Endpoints

### `_cat/fielddata?v`
**What:** Fielddata memory usage per node per field.
**Why:** Fielddata is loaded into heap for sorting/aggregations on `text` fields. A common source of OOM.
**Fix:** Use `keyword` fields for aggregations, or set `indices.fielddata.cache.size` limit.

### `_cat/recovery?v`
**What:** Shard recovery progress.
**Why:** Shows ongoing shard movements — new allocations, rebalancing, or peer recovery after node failure.
**Interpretation:** Stuck recoveries (0 bytes transferred for minutes) indicate network or disk issues.

### `_plugins/_knn/stats`
**What:** k-NN plugin memory and performance stats (OpenSearch only).
**Why:** k-NN graphs live in native memory outside JVM heap. They can exhaust system memory without JVM heap showing pressure.
**Key fields:**
- `circuit_breaker_triggered` — true = k-NN memory limit hit
- `graph_memory_usage` / `graph_memory_usage_percentage`
- `cache_capacity_reached` — true = graph cache full, evictions happening

### `_plugins/_ism/explain/{index}`
**What:** ISM policy execution state (OpenSearch only).
**Why:** Shows if index lifecycle actions are stuck, retrying, or failed.

### `_aliases`
**What:** Index alias mappings.
**Why:** Aliases affect routing. Misconfigured aliases can send queries to wrong indices.

### `_dangling`
**What:** Orphaned indices from departed nodes.
**Why:** After node failures, indices may be left in a dangling state needing manual import or cleanup.

### Search Profiling
```bash
curl -s -X POST "$PROTOCOL://$HOST:$PORT/{index}/_search" -H 'Content-Type: application/json' -d '{
  "profile": true,
  "query": { "match": { "field": "value" } }
}'
```
**Why:** Shows exactly where query time is spent — which shard, which Lucene operation.

## CAT API Quick Reference

| Command | Shows | Sort/Filter |
|---------|-------|-------------|
| `_cat/nodes?v&s=cpu:desc` | Node resource usage | By CPU descending |
| `_cat/indices?v&s=index` | All indices | Alphabetical |
| `_cat/indices?v&health=red` | Only red indices | By health |
| `_cat/shards?v&s=state` | Shard allocation | Unassigned first |
| `_cat/segments/{index}?v` | Per-segment details | Default |
| `_cat/allocation?v&bytes=gb` | Disk allocation per node | Default |
| `_cat/thread_pool/search,write?v` | Thread pool stats | Default |
| `_cat/tasks?v&detailed` | In-flight operations | Default |
| `_cat/fielddata?v` | Fielddata memory | Default |
| `_cat/recovery?v&active_only=true` | Active recoveries only | Default |
| `_cat/plugins?v` | Installed plugins | Default |

## Metric Relationships — Causal Chains

Understanding WHY metrics are connected helps diagnose root causes:

| Observation | + Combined With | Root Cause | Fix |
|-------------|----------------|------------|-----|
| High heap (> 85%) | Many segments per shard (> 50) | Segments hold memory for points, norms, stored fields | `POST {index}/_forcemerge?max_num_segments=1` (off-peak) |
| High heap (> 85%) | High fielddata usage | Aggregations/sorts on `text` fields load fielddata into heap | Switch to `keyword` fields; set fielddata cache limit |
| Circuit breaker trips | High fielddata | Fielddata cache exceeding limits | `indices.fielddata.cache.size: 20%` + use `keyword` |
| Circuit breaker trips | k-NN graph memory high | Vector indices consuming native memory | Reduce dimensions, limit loaded k-NN indices, increase `knn.memory.circuit_breaker.limit` |
| Yellow status | Unassigned shards | Allocation blocked | Check: disk watermarks, `allocation.total_shards_per_node`, node count vs replicas |
| Yellow status | `_cat/recovery` empty | No recovery even attempted | Check allocation explain: `POST _cluster/allocation/explain` |
| Rejected search threads | High CPU on all nodes | Query load exceeds capacity | Optimize queries, add nodes, increase `thread_pool.search.queue_size` (temporary) |
| Rejected write threads | High merge activity | Merges competing with indexing I/O | Increase `index.merge.scheduler.max_thread_count`, use faster disks |
| Slow queries | High segment count | More segments = more files to search | Force merge; review indexing patterns (too many small bulk requests) |
| Slow queries | Profile shows slow collector | Expensive query clause (regex, wildcard leading) | Rewrite query; add keyword field for filtering |
| Pending cluster tasks growing | Too many indices/shards | Master node overwhelmed by cluster state | Reduce shard count, use ILM/ISM to close old indices |

## Common Problems Quick Reference

| Symptom | First Check | Likely Cause | Fix |
|---------|-------------|--------------|-----|
| Red cluster | `_cat/shards?v&s=state` | Missing primary shards | Check node health, restore from snapshot if data lost |
| Yellow cluster | `_cat/shards` + `_cluster/allocation/explain` | Can't allocate replicas | Add nodes, adjust replicas, check disk watermarks |
| OOM / circuit breaker | `_nodes/stats` (breakers + heap) | Heap exhausted | Identify source: fielddata, segments, or bulk queue |
| Slow searches | `{index}/_stats` + profiling | Many segments, expensive queries, or resource contention | Force merge, optimize queries, scale cluster |
| Slow indexing | `_cat/thread_pool/write?v` + `{index}/_stats` (merges) | Merge pressure, rejected writes | Increase refresh_interval, reduce replica count during bulk |
| Disk watermark read-only | `_cat/allocation?v&bytes=gb` | Disk > 90% (flood stage) | Free disk, then `PUT {index}/_settings {"index.blocks.read_only_allow_delete": null}` |
| k-NN slow | `_plugins/_knn/stats` | Graph memory limit, cache evictions | Limit loaded indices, increase memory, reduce dimensions |
| Mapping explosion | `{index}/_mapping` | Dynamic mapping + varied documents | Set `index.mapping.total_fields.limit`, use strict mapping |
