const express = require('express');
const http = require('http');
const socketIo = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = socketIo(server, { cors: { origin: "*" } });

// تخزين الغرف واللاعبين
const rooms = {};

io.on('connection', (socket) => {
  console.log(`لاعب متصل: ${socket.id}`);

  // 1. عند انضمام لاعب إلى غرفة
  socket.on('join_room', ({ roomId, playerName }) => {
    socket.join(roomId);
    if (!rooms[roomId]) {
      rooms[roomId] = { players: [] };
    }
    rooms[roomId].players.push({ id: socket.id, name: playerName, x: 200, y: 200 });

    // إرسال قائمة اللاعبين الحاليين للجميع في الغرفة
    io.to(roomId).emit('update_players', rooms[roomId].players);
    console.log(`${playerName} انضم إلى الغرفة: ${roomId}`);
  });

  // 2. عند تحديث موقع اللاعب
  socket.on('update_position', ({ roomId, playerId, x, y }) => {
    if (rooms[roomId]) {
      const player = rooms[roomId].players.find(p => p.id === playerId);
      if (player) {
        player.x = x;
        player.y = y;
        // بث الموقع الجديد لكل اللاعبين في الغرفة
        socket.to(roomId).emit('opponent_moved', { playerId, x, y });
      }
    }
  });

  // 3. عند إطلاق النار
  socket.on('player_shoot', ({ roomId, x, y, dx, dy }) => {
    socket.to(roomId).emit('opponent_shoot', { x, y, dx, dy });
  });

  // 4. عند انقطاع الاتصال
  socket.on('disconnect', () => {
    // إزالة اللاعب من الغرفة
    for (const roomId in rooms) {
      const index = rooms[roomId].players.findIndex(p => p.id === socket.id);
      if (index !== -1) {
        rooms[roomId].players.splice(index, 1);
        io.to(roomId).emit('update_players', rooms[roomId].players);
        break;
      }
    }
    console.log(`لاعب قطع الاتصال: ${socket.id}`);
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`الخادم يعمل على المنفذ ${PORT}`));
