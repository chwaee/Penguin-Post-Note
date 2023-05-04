import express, { Request, Response } from 'express';
import bodyParser from 'body-parser';
import cors from 'cors';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const app = express();

app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

app.post('/notes', async (req: Request, res: Response) => {
  const { title, content } = req.body;
  try {
    const note = await prisma.note.create({
      data: { title, content },
    });
    res.status(201).send({ id: note.id });
  } catch (err) {
    res.status(500).send(err);
  }
});

app.get('/notes', async (req: Request, res: Response) => {
  try {
    const notes = await prisma.note.findMany();
    res.send(notes);
  } catch (err) {
    res.status(500).send(err);
  }
});

app.get('/notes/:id', async (req: Request, res: Response) => {
  const id = Number(req.params.id);
  try {
    const note = await prisma.note.findUnique({ where: { id } });
    if (!note) return res.status(404).send({ message: 'Note not found' });
    res.send(note);
  } catch (err) {
    res.status(500).send(err);
  }
});

app.put('/notes/:id', async (req: Request, res: Response) => {
  const id = Number(req.params.id);
  const { title, content } = req.body;
  try {
    const note = await prisma.note.update({
      where: { id },
      data: { title, content },
    });
    res.send({ message: 'Note updated successfully', note });
    } catch (err) {
      res.status(500).send(err);
    }
});

app.delete('/notes/:id', async (req: Request, res: Response) => {
    const id = Number(req.params.id);
    try {
        const note = await prisma.note.delete({ where: { id } });
        res.send({ message: 'Note deleted successfully', note });
    } catch (err) {
        res.status(500).send(err);
    }
});
