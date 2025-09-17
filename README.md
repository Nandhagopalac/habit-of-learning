# 📚 Habit of Learning

Track your daily learning habits and monitor progress across different topics using **Supabase** as the backend.  

---

## 🚀 Features
- Log daily learning activities (`topic`, `sub_topic`, `notes`).  
- Track completion status with timestamps.  
- Automatic IST (Asia/Kolkata) timezone handling.  
- Secure row-level access policies for authenticated users.  
- Ready-to-use SQL schema with indexes, triggers, and functions.  

---

## 🛠️ Tech Stack
- **Database**: PostgreSQL (via Supabase)  
- **Auth & Policies**: Supabase RLS (Row Level Security)  
- **Language**: SQL + PL/pgSQL  

---

## 📂 Project Structure
```
habit-of-learning/
│── README.md              # Project overview (this file)
│── sql/
│   ├── schema.sql         # Table definitions + indexes
│   ├── policies.sql       # RLS & access policies
│   ├── functions.sql      # Helper functions (IST conversion, etc.)
│   └── views.sql          # Views for easier querying
│── docs/
│   └── db-setup.md        # Step-by-step database setup guide
```

---

## ⚡ Quick Start

### 1. Clone the repo
```bash
git clone https://github.com/your-username/habit-of-learning.git
cd habit-of-learning
```

### 2. Setup Supabase
- Create a new project in [Supabase](https://supabase.com/).  
- Get your project’s connection string.  

### 3. Run the schema
Apply the SQL scripts in order:
```bash
psql < sql/schema.sql
psql < sql/policies.sql
psql < sql/functions.sql
psql < sql/views.sql
```

### 4. Verify Setup
Run:
```sql
SELECT * FROM study_log LIMIT 5;
```

---

## 🔑 Example Usage

Insert a new learning log:
```sql
INSERT INTO study_log (date, topic, sub_topic, notes, completed)
VALUES (CURRENT_DATE, 'Data Engineering', 'Kafka Basics', 'Learned about partitions', true);
```

Query logs for a date range:
```sql
SELECT * FROM get_study_logs_by_date_range('2025-01-01', '2025-01-31');
```

---

## 🕒 Timezone Handling
- All timestamps are stored in UTC internally.  
- Conversion to **IST (Asia/Kolkata)** is automatic via triggers and helper functions.  

---

## 📜 License
MIT  
