const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function test() {
  try {
    console.log('Testing Prisma connection...');
    
    // Test each table
    const users = await prisma.user.findMany();
    console.log(`✅ Users: ${users.length} records`);
    
    const devices = await prisma.device.findMany();
    console.log(`✅ Devices: ${devices.length} records`);
    
    const conversations = await prisma.conversation.findMany();
    console.log(`✅ Conversations: ${conversations.length} records`);
    
    const messages = await prisma.message.findMany();
    console.log(`✅ Messages: ${messages.length} records`);
    
    console.log('\n✅ All tables accessible!');
  } catch (error) {
    console.error('❌ Error:', error.message);
    console.error('Full error:', error);
  } finally {
    await prisma.$disconnect();
  }
}

test();

