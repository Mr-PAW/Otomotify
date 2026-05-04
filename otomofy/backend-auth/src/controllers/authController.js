const pool = require('../config/database');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

// Helper bikin token
const generateAccessToken = (user) => {
    return jwt.sign(
        { id: user.id, email: user.email },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN }
    );
};

const generateRefreshToken = (user) => {
    return jwt.sign(
        { id: user.id, email: user.email },
        process.env.JWT_REFRESH_SECRET,
        { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN }
    );
};

// REGISTER
exports.register = async (req, res) => {
    try {
        const { name, email, password } = req.body;

        // Cek email sudah terdaftar atau belum
        const existing = await pool.query(
            'SELECT id FROM users WHERE email = $1', [email]
        );
        if (existing.rows.length > 0) {
            return res.status(400).json({ message: 'Email sudah terdaftar' });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Simpan ke database
        const result = await pool.query(
            'INSERT INTO users (name, email, password) VALUES ($1, $2, $3) RETURNING id, name, email, avatar_url',
            [name, email, hashedPassword]
        );

        const user = result.rows[0];
        const accessToken = generateAccessToken(user);
        const refreshToken = generateRefreshToken(user);

        res.status(201).json({
            message: 'Register berhasil',
            user,
            accessToken,
            refreshToken,
        });
    } catch (err) {
        res.status(500).json({ message: 'Server error', error: err.message });
    }
};

// LOGIN
exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        // Cek user ada atau tidak
        const result = await pool.query(
            'SELECT * FROM users WHERE email = $1', [email]
        );
        if (result.rows.length === 0) {
            return res.status(401).json({ message: 'Email atau password salah' });
        }

        const user = result.rows[0];

        // Verifikasi password
        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ message: 'Email atau password salah' });
        }

        const accessToken = generateAccessToken(user);
        const refreshToken = generateRefreshToken(user);

        res.json({
            message: 'Login berhasil',
            user: { id: user.id, name: user.name, email: user.email },
            accessToken,
            refreshToken,
        });
    } catch (err) {
        res.status(500).json({ message: 'Server error', error: err.message });
    }
};

// REFRESH TOKEN
exports.refresh = async (req, res) => {
    try {
        const { refreshToken } = req.body;
        if (!refreshToken) {
            return res.status(401).json({ message: 'Refresh token tidak ada' });
        }

        const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
        const result = await pool.query(
            'SELECT id, name, email FROM users WHERE id = $1', [decoded.id]
        );

        if (result.rows.length === 0) {
            return res.status(401).json({ message: 'User tidak ditemukan' });
        }

        const user = result.rows[0];
        const accessToken = generateAccessToken(user);

        res.json({ accessToken });
    } catch (err) {
        res.status(401).json({ message: 'Refresh token tidak valid' });
    }
};

// ME (get current user)
exports.me = async (req, res) => {
    try {
        const result = await pool.query(
            'SELECT id, name, email, avatar_url FROM users WHERE id = $1', [req.user.id]
        );
        res.json({ user: result.rows[0] });
    } catch (err) {
        res.status(500).json({ message: 'Server error', error: err.message });
    }
};

// UPDATE PROFILE (name + email)
exports.updateProfile = async (req, res) => {
    try {
        const { name, email } = req.body;
        const userId = req.user.id;

        if (!name || !email) {
            return res.status(400).json({ message: 'Nama dan email wajib diisi' });
        }

        // Check if email is taken by another user
        const existing = await pool.query(
            'SELECT id FROM users WHERE email = $1 AND id != $2', [email, userId]
        );
        if (existing.rows.length > 0) {
            return res.status(400).json({ message: 'Email sudah digunakan akun lain' });
        }

        const result = await pool.query(
            'UPDATE users SET name = $1, email = $2 WHERE id = $3 RETURNING id, name, email, avatar_url',
            [name, email, userId]
        );

        res.json({ message: 'Profil berhasil diperbarui', user: result.rows[0] });
    } catch (err) {
        res.status(500).json({ message: 'Server error', error: err.message });
    }
};

// CHANGE PASSWORD
exports.changePassword = async (req, res) => {
    try {
        const { oldPassword, newPassword } = req.body;
        const userId = req.user.id;

        if (!oldPassword || !newPassword) {
            return res.status(400).json({ message: 'Password lama dan baru wajib diisi' });
        }
        if (newPassword.length < 6) {
            return res.status(400).json({ message: 'Password baru minimal 6 karakter' });
        }

        // Fetch current hashed password
        const result = await pool.query('SELECT password FROM users WHERE id = $1', [userId]);
        if (result.rows.length === 0) {
            return res.status(404).json({ message: 'User tidak ditemukan' });
        }

        const isMatch = await bcrypt.compare(oldPassword, result.rows[0].password);
        if (!isMatch) {
            return res.status(400).json({ message: 'Password lama tidak benar' });
        }

        const hashedPassword = await bcrypt.hash(newPassword, 10);
        await pool.query('UPDATE users SET password = $1 WHERE id = $2', [hashedPassword, userId]);

        res.json({ message: 'Password berhasil diubah' });
    } catch (err) {
        res.status(500).json({ message: 'Server error', error: err.message });
    }
};