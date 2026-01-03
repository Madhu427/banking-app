const express = require('express');
const app = express();
app.get('/', (req, res) => res.send('Account Service Active'));
app.listen(3000);
