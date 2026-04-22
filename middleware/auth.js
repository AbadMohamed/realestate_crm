const jwt = require('jsonwebtoken');

const auth = (roles = []) => {
  if (typeof roles === 'string') roles = [roles];
  return (req, res, next) => {
    // Accept token from Authorization header OR ?token= query param
    // The query param method is needed when the browser opens a PDF URL
    // directly in a new tab (no way to set headers in that case).
    const header = req.headers['authorization'];
    let token = null;

    if (header && header.startsWith('Bearer ')) {
      token = header.split(' ')[1];
    } else if (req.query && req.query.token) {
      token = req.query.token;
    }

    if (!token) {
      return res.status(401).json({ message: 'No token provided' });
    }

    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      req.user = decoded;
      if (roles.length && !roles.includes(decoded.role))
        return res.status(403).json({ message: 'Insufficient permissions' });
      next();
    } catch {
      return res.status(401).json({ message: 'Invalid or expired token' });
    }
  };
};

module.exports = auth;