# MongoDB Patterns

**Purpose**: Guide for MongoDB database design, patterns, and optimization

## SCHEMA DESIGN

### Embedding vs Referencing

#### Embedding
- **Use When**: 
  - Data is accessed together
  - One-to-one or one-to-few relationships
  - Data grows together
  - Performance is critical (no joins)
- **Pros**: 
  - No joins required (faster reads)
  - Atomic updates (single document)
  - Better read performance
- **Cons**: 
  - Document size limit (16MB)
  - Duplication (data redundancy)
  - Larger documents

#### Referencing
- **Use When**:
  - Many-to-many relationships
  - One-to-many with many children
  - Data accessed independently
  - Data size varies significantly
- **Pros**:
  - Smaller documents
  - No duplication
  - Flexible relationships
- **Cons**:
  - Requires application-level joins
  - Slower reads (multiple queries)
  - Non-atomic updates

### Schema Patterns

#### One-to-One: Embedding
```javascript
// Good: Embedding for 1:1
const userSchema = new Schema({
  name: String,
  email: String,
  profile: {
    age: Number,
    bio: String
  }
});

// Query
User.findOne({ name: 'John' });
```

#### One-to-Many: Embedding (Few)
```javascript
// Good: Embedding for 1:few (< 100 children)
const postSchema = new Schema({
  title: String,
  content: String,
  comments: [{
    author: String,
    text: String,
    createdAt: Date
  }]
});

// Query
Post.findOne({ title: 'My Post' });
```

#### One-to-Many: Referencing (Many)
```javascript
// Good: Referencing for 1:many (> 100 children)
const userSchema = new Schema({
  name: String,
  email: String
});

const postSchema = new Schema({
  title: String,
  content: String,
  userId: { type: Schema.Types.ObjectId, ref: 'User' }
});

// Query with population
Post.find({ userId: user._id }).populate('userId');
```

#### Many-to-Many: Referencing
```javascript
// Good: Referencing for M:N
const userSchema = new Schema({
  name: String,
  posts: [{ type: Schema.Types.ObjectId, ref: 'Post' }]
});

const postSchema = new Schema({
  title: String,
  authors: [{ type: Schema.Types.ObjectId, ref: 'User' }]
});

// Query
User.findOne({ name: 'John' }).populate('posts');
```

## INDEXING

### Index Types

#### Single Field Index
```javascript
// Create single field index
db.users.createIndex({ email: 1 });

// Query
db.users.findOne({ email: 'john@example.com' });
```

#### Compound Index
```javascript
// Create compound index
db.users.createIndex({ name: 1, email: 1 });

// Query (uses index)
db.users.find({ name: 'John', email: 'john@example.com' });

// Query (partial index usage)
db.users.find({ name: 'John' });  // Uses name field of compound index
```

#### Multikey Index (Array)
```javascript
// Create multikey index on array field
db.users.createIndex({ tags: 1 });

// Query
db.users.find({ tags: 'mongodb' });
```

#### Text Index
```javascript
// Create text index
db.posts.createIndex({ title: 'text', content: 'text' });

// Query
db.posts.find({ $text: { $search: 'mongodb tutorial' } });
```

#### Geospatial Index
```javascript
// Create 2dsphere index
db.places.createIndex({ location: '2dsphere' });

// Query
db.places.find({
  location: {
    $near: {
      $geometry: { type: 'Point', coordinates: [-73.9667, 40.78] },
      $maxDistance: 1000  // meters
    }
  }
});
```

#### TTL Index
```javascript
// Create TTL index (expires after 3600 seconds)
db.sessions.createIndex({ createdAt: 1 }, { expireAfterSeconds: 3600 });

// Document
{
  _id: ObjectId("..."),
  createdAt: new Date()
}
```

### Index Best Practices
- **E-S-R Rule**: Equality, Sort, Range
  - Equality fields first
  - Sort fields next
  - Range fields last
- **Covered Queries**: Index includes all required fields
- **Index Selectivity**: High selectivity indexes (unique > low cardinality)
- **Avoid Too Many Indexes**: Indexes slow down writes
- **Monitor Index Usage**: Use `$indexStats` to check index usage

## AGGREGATION PIPELINE

### Common Stages

#### $match (Filter)
```javascript
db.users.aggregate([
  { $match: { age: { $gte: 18 } } }
]);
```

#### $group (Group)
```javascript
db.orders.aggregate([
  { $group: {
    _id: '$customerId',
    totalSpent: { $sum: '$amount' },
    orderCount: { $sum: 1 }
  }}
]);
```

#### $project (Select)
```javascript
db.users.aggregate([
  { $project: {
    name: 1,
    email: 1,
    ageCategory: {
      $cond: {
        if: { $lt: ['$age', 18] },
        then: 'minor',
        else: 'adult'
      }
    }
  }}
]);
```

#### $lookup (Left Join)
```javascript
db.orders.aggregate([
  { $lookup: {
    from: 'users',
    localField: 'userId',
    foreignField: '_id',
    as: 'user'
  }}
]);
```

#### $unwind (Flatten Arrays)
```javascript
db.posts.aggregate([
  { $unwind: '$tags' }
]);
```

#### $sort
```javascript
db.users.aggregate([
  { $sort: { createdAt: -1 } }
]);
```

#### $limit and $skip
```javascript
db.users.aggregate([
  { $skip: 10 },
  { $limit: 10 }
]);
```

### Aggregation Examples

#### Sales Report
```javascript
db.orders.aggregate([
  { $match: { createdAt: { $gte: new Date('2024-01-01') } } },
  { $group: {
    _id: { $dateToString: { format: '%Y-%m', date: '$createdAt' } },
    totalRevenue: { $sum: '$amount' },
    orderCount: { $sum: 1 }
  }},
  { $sort: { _id: 1 } }
]);
```

#### User Activity
```javascript
db.userActivities.aggregate([
  { $match: { action: 'login' } },
  { $group: {
    _id: '$userId',
    loginCount: { $sum: 1 },
    lastLogin: { $max: '$timestamp' }
  }},
  { $sort: { loginCount: -1 } },
  { $limit: 10 }
]);
```

## PERFORMANCE OPTIMIZATION

### Query Optimization

#### Covered Queries
```javascript
// Create covered index
db.users.createIndex({ email: 1, name: 1 });

// Query (covered - no document fetch)
db.users.find({ email: 'john@example.com' }, { _id: 0, name: 1 });
```

#### Projection
```javascript
// Good: Only select needed fields
db.users.find(
  { email: 'john@example.com' },
  { name: 1, age: 1 }
);

// Bad: Select all fields
db.users.find({ email: 'john@example.com' });
```

#### Limit Results
```javascript
// Good: Always limit results
db.users.find({ age: { $gte: 18 } }).limit(100);

// Good: Use pagination
db.users.find({ age: { $gte: 18 } }).skip(100).limit(10);
```

### Write Optimization

#### Bulk Operations
```javascript
// Good: Bulk insert
db.users.insertMany([
  { name: 'John', email: 'john@example.com' },
  { name: 'Jane', email: 'jane@example.com' },
  // ... more documents
]);

// Good: Bulk write operations
db.collection('users').bulkWrite([
  { insertOne: { document: { name: 'Bob' } } },
  { updateOne: { filter: { name: 'Alice' }, update: { $set: { age: 30 } } } },
  { deleteOne: { filter: { name: 'Charlie' } } }
]);
```

#### Write Concerns
```javascript
// Development: Acknowledged (fast)
db.users.insertOne({ name: 'John' }, { writeConcern: { w: 1 } });

// Production: Replica set acknowledged (safer)
db.users.insertOne({ name: 'John' }, { writeConcern: { w: 'majority' } });
```

## COMMON MISTAKES

### Schema Mistakes
- [ ] **Over-embedding**: Embedding too much data (> 1MB)
- [ ] **Under-referencing**: Not using referencing for large arrays
- [ ] **No Indexes**: Missing indexes on queried fields
- [ ] **Too Many Indexes**: Indexing too many fields (slow writes)
- [ ] **Large Documents**: Documents approaching 16MB limit
- [ ] **No Shard Key**: Not planning for sharding

### Query Mistakes
- [ ] **SELECT ***: Fetching entire documents unnecessarily
- [ ] **No Projection**: Not using projection to limit fields
- [ ] **No Limit**: Not limiting query results
- [ ] **Regex Leading Wildcard**: `^field` prevents index usage
- [ ] **Large $or**: Too many $or conditions (slow)
- [ ] **$nin Queries**: $nin queries are slow

### Aggregation Mistakes
- [ ] **$unwind Large Arrays**: Unwinding large arrays is slow
- [ ] **Too Many Stages**: Too many aggregation stages
- [ ] **No $match Early**: Not filtering early in pipeline
- [ ] **Memory Limit**: Aggregation exceeding 100MB memory limit
- [ ] **No Indexes on $match**: $match without index

## SHARDING STRATEGIES

### Shard Keys

#### Choosing Shard Key
- **Cardinality**: High cardinality (many distinct values)
- **Frequency**: Even distribution (no hotspots)
- **Query Pattern**: Shard key should be in most queries
- **Immutability**: Shard key should not change

### Shard Key Examples

#### Good Shard Keys
```javascript
// Hashed shard key (good distribution)
db.users.createIndex({ _id: 'hashed' });

// Ranged shard key (good for range queries)
db.logs.createIndex({ timestamp: 1 });

// Compound shard key
db.orders.createIndex({ customerId: 1, orderDate: 1 });
```

#### Bad Shard Keys
```javascript
// Low cardinality (all docs in one shard)
db.users.createIndex({ status: 1 });

// Hotspot (one customer has many orders)
db.orders.createIndex({ customerId: 1 });

// Mutable shard key
db.users.createIndex({ currentLocation: 1 });  // Location changes
```

## MONGOOSE SPECIFICS

### Schema Design
```javascript
const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const userSchema = new Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  age: { type: Number, min: 0 },
  createdAt: { type: Date, default: Date.now }
});

// Add index
userSchema.index({ email: 1 }, { unique: true });
userSchema.index({ age: 1 });

const User = mongoose.model('User', userSchema);
```

### Virtual Fields
```javascript
userSchema.virtual('isAdult').get(function() {
  return this.age >= 18;
});

// Query (virtual not in database)
User.findOne({ name: 'John' }).exec(function(err, user) {
  console.log(user.isAdult);  // true or false
});
```

### Middleware
```javascript
// Pre-save middleware
userSchema.pre('save', function(next) {
  this.email = this.email.toLowerCase();
  next();
});

// Post-save middleware
userSchema.post('save', function(doc) {
  console.log('User saved:', doc._id);
});
```

### Population
```javascript
const postSchema = new Schema({
  title: String,
  author: { type: Schema.Types.ObjectId, ref: 'User' }
});

const Post = mongoose.model('Post', postSchema);

// Query with population
Post.find({ title: 'My Post' })
  .populate('author', 'name email')
  .exec(function(err, posts) {
    // posts[0].author.name
  });
```
