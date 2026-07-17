const User = require('../models/User');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');

// Helper to generate token
const generateToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET || 'fallback_secret', {
    expiresIn: '30d',
  });
};

// @desc    Register User
// @route   POST /api/auth/register
// @access  Public
exports.register = async (req, res) => {
  try {
    const { name, email, password, role, referredByCode } = req.body;

    const userExists = await User.findOne({ email });
    if (userExists) {
      return res.status(400).json({ success: false, message: 'User already exists' });
    }

    // Generate unique referral code for the new user
    const referralCode = Math.random().toString(36).substring(2, 8).toUpperCase();

    // Fetch dynamic rewards configuration
    const PlatformConfig = require('../models/PlatformConfig');
    let config = await PlatformConfig.findOne();
    if (!config) {
      config = {
        initialWelcomeCoins: 0,
        referralRefereeReward: 50,
        referralReferrerReward: 50
      };
    }

    // Check if referred by someone
    let referredBy = null;
    if (referredByCode) {
      const actualReferrer = await User.findOne({ referralCode: referredByCode.toUpperCase() });
      if (actualReferrer) {
        referredBy = actualReferrer._id;
        // Credit referrer with referral coins
        actualReferrer.coins = (actualReferrer.coins || 0) + config.referralReferrerReward;
        await actualReferrer.save();
      }
    }

    const user = await User.create({
      name,
      email,
      password,
      role: role || 'Student',
      referralCode,
      referredBy,
      coins: referredBy ? config.referralRefereeReward : config.initialWelcomeCoins,
    });

    res.status(201).json({
      success: true,
      token: generateToken(user._id),
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        coins: user.coins,
        avatar: user.avatar,
        referralCode: user.referralCode,
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Login User
// @route   POST /api/auth/login
// @access  Public
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ success: false, message: 'Invalid email or password' });
    }

    res.status(200).json({
      success: true,
      token: generateToken(user._id),
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        coins: user.coins,
        avatar: user.avatar,
        referralCode: user.referralCode,
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get Current Logged In User
// @route   GET /api/auth/me
// @access  Private
exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    res.status(200).json({ success: true, user });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Google OAuth Signin
// @route   POST /api/auth/google
// @access  Public
exports.googleLogin = async (req, res) => {
  try {
    const { token } = req.body;
    let { name, email, avatar } = req.body;
    console.log('Incoming Google Login Request: name =', name, ', email =', email, ', avatar =', avatar);

    // Secure verification if GOOGLE_CLIENT_ID is active in the environment
    if (process.env.GOOGLE_CLIENT_ID && token) {
      console.log('Verifying Google Token...', token.substring(0, 20) + '...');
      try {
        const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
        // Allow both the Web Client ID and Android Client ID as valid audiences
        const ticket = await client.verifyIdToken({
          idToken: token,
          audience: [
            process.env.GOOGLE_CLIENT_ID,
            '1032186678329-6f271ih981tftgrodk6pathbov93i9h9.apps.googleusercontent.com'
          ],
          clockSkew: 300 // Allow up to 5 minutes of local system clock drift
        });
        const payload = ticket.getPayload();
        email = payload.email;
        name = payload.name;
        avatar = payload.picture;
      } catch (verificationError) {
        console.log('Provided token is not a JWT ID Token. Attempting Access Token verification fallback...');
        try {
          const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
          const tokenInfo = await client.getTokenInfo(token);
          
          const allowedAudiences = [
            process.env.GOOGLE_CLIENT_ID,
            '1032186678329-6f271ih981tftgrodk6pathbov93i9h9.apps.googleusercontent.com'
          ];
          
          if (!allowedAudiences.includes(tokenInfo.aud)) {
            console.error('Audience mismatch for access token. Expected:', allowedAudiences, 'Got:', tokenInfo.aud);
            throw new Error('Access token audience mismatch');
          }
          
          email = tokenInfo.email;

          // Fetch the user's real name and profile picture from Google UserInfo API using the access token
          try {
            const https = require('https');
            const userInfo = await new Promise((resolve, reject) => {
              https.get(`https://www.googleapis.com/oauth2/v3/userinfo?access_token=${token}`, (res) => {
                let data = '';
                res.on('data', (chunk) => data += chunk);
                res.on('end', () => {
                  try {
                    resolve(JSON.parse(data));
                  } catch (e) {
                    reject(e);
                  }
                });
              }).on('error', (err) => reject(err));
            });

            if (userInfo.picture) {
              avatar = userInfo.picture;
            }
            if (userInfo.name) {
              name = userInfo.name;
            }
          } catch (userInfoError) {
            console.warn('Failed to retrieve userinfo from Google:', userInfoError.message);
          }
        } catch (accessTokenError) {
          console.error('All Google token verification methods failed:', accessTokenError.message);
          return res.status(401).json({ success: false, message: 'Invalid Google identity token or access token' });
        }
      }
    }

    if (!email) {
      return res.status(400).json({ success: false, message: 'Email address is required for Google login' });
    }

    let user = await User.findOne({ email });

    if (!user) {
      const referralCode = Math.random().toString(36).substring(2, 8).toUpperCase();
      user = await User.create({
        name,
        email,
        password: Math.random().toString(36).substring(2, 10), // temporary random password
        referralCode,
        avatar: avatar || 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=120',
      });
    } else if (avatar && (!user.avatar || user.avatar.includes('photo-1535713875002-d1d0cf377fde'))) {
      user.avatar = avatar;
      await user.save();
    }

    res.status(200).json({
      success: true,
      token: generateToken(user._id),
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        coins: user.coins,
        avatar: user.avatar,
        phone: user.phone || '',
        college: user.college || '',
        department: user.department || '',
        bio: user.bio || '',
        referralCode: user.referralCode,
        isProfileComplete: user.isProfileComplete || false,
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Mock OTP verification
// @route   POST /api/auth/otp/verify
// @access  Public
exports.verifyOtp = async (req, res) => {
  const { email, code } = req.body;
  // Mock verification: allow code '1234'
  if (code === '1234') {
    res.status(200).json({ success: true, message: 'OTP verified successfully' });
  } else {
    res.status(400).json({ success: false, message: 'Invalid OTP verification code' });
  }
};

// @desc    Mock Password recovery
// @route   POST /api/auth/forgot-password
// @access  Public
exports.forgotPassword = async (req, res) => {
  const { email } = req.body;
  const user = await User.findOne({ email });
  if (!user) {
    return res.status(404).json({ success: false, message: 'Email address not found' });
  }
  res.status(200).json({ success: true, message: 'Reset password link sent to your email.' });
};

// @desc    Get User Addresses
// @route   GET /api/auth/addresses
// @access  Private
exports.getAddresses = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    res.status(200).json({ success: true, data: user.addresses || [] });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Add User Address
// @route   POST /api/auth/addresses
// @access  Private
exports.addAddress = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    
    const { fullName, phoneNumber, addressLine, city, state, pinCode, isDefault } = req.body;
    
    // If setting default, unset others first
    if (isDefault) {
      user.addresses.forEach(addr => addr.isDefault = false);
    }
    
    user.addresses.push({ fullName, phoneNumber, addressLine, city, state, pinCode, isDefault });
    await user.save();
    
    res.status(200).json({ success: true, data: user.addresses });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Delete User Address
// @route   DELETE /api/auth/addresses/:id
// @access  Private
exports.deleteAddress = async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    
    user.addresses.pull({ _id: req.params.id });
    await user.save();
    
    res.status(200).json({ success: true, data: user.addresses });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Update User Profile
// @route   PUT /api/auth/profile
// @access  Private
exports.updateProfile = async (req, res) => {
  try {
    const { name, phone, college, department, role, bio, avatar } = req.body;
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });

    if (name) user.name = name.trim();
    if (phone !== undefined) user.phone = phone;
    if (college !== undefined) user.college = college;
    if (department !== undefined) user.department = department;
    if (role && ['Student', 'Teacher'].includes(role)) user.role = role;
    if (bio !== undefined) user.bio = bio;
    if (avatar) user.avatar = avatar;

    // Mark profile as complete if required fields are filled
    if (user.name && user.phone && user.college && user.department) {
      user.isProfileComplete = true;
    }

    await user.save();

    res.status(200).json({
      success: true,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        coins: user.coins,
        avatar: user.avatar,
        phone: user.phone,
        college: user.college,
        department: user.department,
        bio: user.bio,
        referralCode: user.referralCode,
        isProfileComplete: user.isProfileComplete,
      }
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

