# Prisma Studio Guide - How to Use

## 🚀 Quick Start

### Step 1: Start Prisma Studio

Open Terminal and run:

```bash
cd /Users/david/Desktop/ChatOnWrist/backend
npm run studio
```

**OR** use the helper script:

```bash
cd /Users/david/Desktop/ChatOnWrist/backend
./start-studio.sh
```

### Step 2: Open in Browser

After running the command, you'll see:
```
Prisma Studio is up on http://localhost:5555
```

**Open your web browser** and go to:
```
http://localhost:5555
```

## 📊 What You'll See

When Prisma Studio opens, you'll see a list of your database tables:

- **User** - All users who signed in
- **Device** - iPhone and Watch devices
- **Conversation** - All chat conversations
- **Message** - All messages in conversations
- **PairingCode** - Device pairing codes

## 🖱️ How to Use

### View Data

1. **Click on any table name** (e.g., "User" or "Conversation")
2. You'll see all records in that table
3. Each row is a record (e.g., one user, one conversation)

### Search/Filter

- Use the **search box** at the top to find specific records
- Click **"Filter"** to add filters (e.g., find users created after a date)

### View Relationships

- Click on a record to see details
- Click on **relationship links** (e.g., "devices" or "messages") to see related data
- Example: Click a User → See their Devices → See Conversations → See Messages

### Add New Record

1. Click the **"+"** button or **"Add record"**
2. Fill in the fields
3. Click **"Save"**

### Edit Record

1. Click on any record
2. Click **"Edit"**
3. Change the values
4. Click **"Save"**

### Delete Record

1. Click on a record
2. Click **"Delete"** button
3. Confirm deletion

## 📝 Example: View All Users

1. Start Prisma Studio: `npm run studio`
2. Open browser: `http://localhost:5555`
3. Click **"User"** in the left sidebar
4. See all users with their:
   - ID
   - Apple User ID
   - Email
   - Created date

## 📝 Example: View Conversations and Messages

1. Click **"Conversation"** table
2. See all conversations
3. Click on a conversation to see details
4. Click **"messages"** link to see all messages in that conversation

## 🛑 Stop Prisma Studio

- Press **Ctrl+C** in the terminal where it's running
- Or close the terminal window

## ❓ Common Questions

**Q: I see "No records found"**
- Your database is empty (no users/conversations yet)
- This is normal if you haven't used the app yet

**Q: Can I edit data?**
- Yes! Click any record → Edit → Save

**Q: Will changes affect my app?**
- Yes! Changes in Prisma Studio directly modify your database
- Be careful when deleting records

**Q: The page won't load**
- Make sure Prisma Studio is running (check terminal)
- Try refreshing the browser
- Make sure port 5555 isn't blocked

## 🎯 What to Do Right Now

1. **Open Terminal**
2. **Run**: `cd /Users/david/Desktop/ChatOnWrist/backend && npm run studio`
3. **Wait** for "Prisma Studio is up" message
4. **Open browser** → Go to `http://localhost:5555`
5. **Click** on table names to explore your data!

That's it! Prisma Studio is just a visual way to see and edit your database.

