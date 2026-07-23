const Note = require('../models/Note');
const Review = require('../models/Review');
const Report = require('../models/Report');
const { uploadToCloudinary } = require('../config/cloudinary');

// @desc    Upload new Note
// @route   POST /api/notes
// @access  Private (Student/Teacher)
exports.uploadNote = async (req, res) => {
  console.log('Received Note Upload request. body:', req.body, 'files:', req.files);
  try {
    const { title, description, college, department, semester, subject, price, tags, itemType, physicalCategory, itemCondition } = req.body;

    const type = itemType || 'Digital';
    const isPhysical = type === 'Physical';

    let fileUrl;
    let thumbnailUrl;
    let imageUrls = [];

    // Process multi-part uploads via Cloudinary stream utility with resilient try-catch fallbacks
    if (req.files) {
      if (req.files['file'] && req.files['file'][0]) {
        try {
          fileUrl = await uploadToCloudinary(req.files['file'][0].buffer, 'raw', req.files['file'][0].originalname);
          // Cloudinary raw uploads strip the extension from the URL.
          // Append .pdf so the file is served with the correct MIME type.
          const origName = req.files['file'][0].originalname || '';
          if (fileUrl && origName.toLowerCase().endsWith('.pdf') && !fileUrl.toLowerCase().endsWith('.pdf')) {
            fileUrl = fileUrl + '.pdf';
          }

          // Generate first page thumbnail dynamically if it's a PDF note
          if (!isPhysical) {
            const fileName = req.files['file'][0].originalname || '';
            if (fileName.toLowerCase().endsWith('.pdf')) {
              try {
                console.log('Generating thumbnail for PDF:', fileName);
                const { pdfToPng } = require('pdf-to-png-converter');
                const pngPages = await pdfToPng(req.files['file'][0].buffer, {
                  pagesToProcess: [1],
                  viewportScale: 1.2,
                });
                
                if (pngPages && pngPages.length > 0 && pngPages[0].content) {
                  console.log('PDF Page 1 rendered successfully. Uploading page 1 as thumbnail...');
                  thumbnailUrl = await uploadToCloudinary(pngPages[0].content, 'image');
                }
              } catch (pdfError) {
                console.error('Failed to generate PDF thumbnail:', pdfError.message || pdfError);
              }
            }
          }
        } catch (cloudinaryError) {
          console.error('Cloudinary raw file upload failed (using fallback):', cloudinaryError.message || cloudinaryError);
        }
      }
      if (req.files['thumbnail'] && req.files['thumbnail'][0]) {
        try {
          thumbnailUrl = await uploadToCloudinary(req.files['thumbnail'][0].buffer, 'image');
        } catch (cloudinaryError) {
          console.error('Cloudinary image upload failed (using fallback):', cloudinaryError.message || cloudinaryError);
        }
      }
      if (req.files['images']) {
        for (const file of req.files['images']) {
          try {
            const url = await uploadToCloudinary(file.buffer, 'image');
            imageUrls.push(url);
          } catch (cloudinaryError) {
            console.error('Cloudinary image upload failed for gallery:', cloudinaryError.message || cloudinaryError);
          }
        }
      }
    }

    // Dynamic fallbacks if no files were uploaded or Cloudinary setup was skipped
    if (!isPhysical && !fileUrl) {
      fileUrl = 'https://res.cloudinary.com/demo/image/upload/v1/notes_sample.pdf';
    }
    if (!thumbnailUrl) {
      thumbnailUrl = imageUrls.length > 0
        ? imageUrls[0]
        : (isPhysical 
            ? 'https://res.cloudinary.com/demo/image/upload/v1/sample_product.jpg'
            : 'https://res.cloudinary.com/demo/image/upload/v1/notes_thumbnail_sample.jpg');
    }
    
    // Ensure images array contains at least the thumbnail for physical items
    if (isPhysical && imageUrls.length === 0 && thumbnailUrl) {
      imageUrls.push(thumbnailUrl);
    }

    console.log('Creating note in MongoDB with fileUrl:', fileUrl, 'thumbnailUrl:', thumbnailUrl, 'images:', imageUrls);
    const note = await Note.create({
      title,
      description,
      college: isPhysical ? undefined : college,
      department: isPhysical ? undefined : (department || 'General'),
      semester: isPhysical ? undefined : (semester ? parseInt(semester, 10) : 1),
      subject: isPhysical ? undefined : subject,
      price: price ? parseFloat(price) : 0,
      tags: tags ? (Array.isArray(tags) ? tags : tags.split(',')) : [],
      fileUrl,
      thumbnailUrl,
      images: imageUrls,
      seller: req.user.id,
      status: 'Pending',
      itemType: type,
      physicalCategory: isPhysical ? (physicalCategory || 'Electronics') : 'None',
      itemCondition: isPhysical ? (itemCondition || 'Good') : 'None',
    });

    console.log('Note saved successfully to MongoDB with id:', note._id);

    // Notify all admin users of a new pending note review
    try {
      const User = require('../models/User');
      const Notification = require('../models/Notification');
      const admins = await User.find({ role: 'Admin' });
      for (const admin of admins) {
        await Notification.create({
          user: admin._id,
          title: '📝 New Note Pending Review',
          message: `A new note "${note.title}" has been uploaded and is pending approval.`,
          type: 'Promo',
        });
      }
    } catch (notifErr) {
      console.error('Failed to notify admins of new note:', notifErr.message);
    }

    res.status(201).json({ success: true, data: note });
  } catch (err) {
    console.error('Note upload error:', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get all Notes with search filters
// @route   GET /api/notes
// @access  Public
exports.getNotes = async (req, res) => {
  try {
    const { search, college, subject, priceType, semester, department, rating, priceMin, priceMax, language, sortBy, page, limit, itemType } = req.query;
    const query = { status: 'Approved', isSold: { $ne: true } }; // only show approved, unsold notes

    if (itemType) {
      query.itemType = itemType;
    }

    // Text Search
    if (search) {
      query.$text = { $search: search };
    }

    // Filters
    if (college && college !== 'All') {
      query.college = college;
    }
    if (subject && subject !== 'All') {
      query.subject = subject;
    }
    if (semester && semester !== 'All') {
      query.semester = parseInt(semester, 10);
    }
    if (department && department !== 'All') {
      query.department = department;
    }
    if (rating) {
      query.averageRating = { $gte: parseFloat(rating) };
    }
    if (priceMin || priceMax) {
      query.price = {};
      if (priceMin) query.price.$gte = parseFloat(priceMin);
      if (priceMax) query.price.$lte = parseFloat(priceMax);
    } else if (priceType) {
      if (priceType === 'Free') {
        query.price = 0;
      } else if (priceType === 'Paid') {
        query.price = { $gt: 0 };
      }
    }
    if (language && language !== 'All') {
      query.tags = language; // assume language is tagged in the document
    }

    // Sorting
    let sortOption = { createdAt: -1 }; // default: newest
    if (sortBy) {
      if (sortBy === 'Popular') {
        sortOption = { downloadsCount: -1 };
      } else if (sortBy === 'Rating') {
        sortOption = { averageRating: -1 };
      } else if (sortBy === 'PriceLow') {
        sortOption = { price: 1 };
      } else if (sortBy === 'PriceHigh') {
        sortOption = { price: -1 };
      }
    }

    // Pagination
    const pageNum = parseInt(page, 10) || 1;
    const limitNum = parseInt(limit, 10) || 10;
    const skip = (pageNum - 1) * limitNum;

    const notes = await Note.find(query)
      .populate('seller', 'name email avatar college followers following addresses')
      .skip(skip)
      .limit(limitNum)
      .sort(sortOption);

    const total = await Note.countDocuments(query);

    res.status(200).json({
      success: true,
      count: notes.length,
      total,
      pages: Math.ceil(total / limitNum),
      data: notes,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get Single Note details
// @route   GET /api/notes/:id
// @access  Public
exports.getNoteById = async (req, res) => {
  try {
    const note = await Note.findById(req.params.id).populate('seller', 'name email avatar college followers following addresses');
    if (!note) {
      return res.status(404).json({ success: false, message: 'Note not found' });
    }
    const relatedNotes = await Note.find({
      subject: note.subject,
      _id: { $ne: note._id },
      status: 'Approved',
      isSold: { $ne: true }
    }).limit(5).populate('seller', 'name email avatar followers following addresses');

    const frequentlyBought = await Note.find({
      category: note.category,
      _id: { $ne: note._id },
      status: 'Approved',
      isSold: { $ne: true }
    }).sort({ price: 1 }).limit(3).populate('seller', 'name email avatar followers following addresses');

    res.status(200).json({ success: true, data: note, relatedNotes, frequentlyBought });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Add Review for Note
// @route   POST /api/notes/:id/reviews
// @access  Private
exports.reviewNote = async (req, res) => {
  try {
    const { rating, comment } = req.body;
    const note = await Note.findById(req.params.id);

    if (!note) {
      return res.status(404).json({ success: false, message: 'Note not found' });
    }

    const review = await Review.create({
      user: req.user.id,
      note: req.params.id,
      rating: parseInt(rating, 10),
      comment,
    });

    // Update average rating
    const reviews = await Review.find({ note: req.params.id });
    const avg = reviews.reduce((acc, r) => acc + r.rating, 0) / reviews.length;
    
    note.averageRating = parseFloat(avg.toFixed(1));
    await note.save();

    res.status(201).json({ success: true, data: review });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Audit / Approve note
// @route   PUT /api/notes/:id/status
// @access  Private (Admin)
exports.updateNoteStatus = async (req, res) => {
  try {
    const { status } = req.body; // Approved or Rejected
    const note = await Note.findById(req.params.id);

    if (!note) {
      return res.status(404).json({ success: false, message: 'Note not found' });
    }

    note.status = status;

    const Notification = require('../models/Notification');

    // Notify seller of Note Approval / Rejection
    try {
      if (status === 'Approved') {
        await Notification.create({
          user: note.seller,
          title: '✅ Note Approved!',
          message: `Your note "${note.title}" has been reviewed and approved by the admin. It is now live in the marketplace!`,
          type: 'Promo',
        });
      } else if (status === 'Rejected') {
        await Notification.create({
          user: note.seller,
          title: '❌ Note Rejected',
          message: `Your note "${note.title}" has been reviewed and rejected by the admin.`,
          type: 'Promo',
        });
      }
    } catch (notifErr) {
      console.error('Note status update notification failed (non-fatal):', notifErr.message);
    }

    // Award coins to the creator if approved for the first time
    if (status === 'Approved' && !note.rewardedForApproval) {
      const User = require('../models/User');
      const PlatformConfig = require('../models/PlatformConfig');
      let config = await PlatformConfig.findOne();
      if (!config) {
        config = { noteApprovalReward: 50 };
      }
      const seller = await User.findById(note.seller);
      if (seller) {
        const rewardCoins = config.noteApprovalReward || 50;
        seller.coins = (seller.coins || 0) + rewardCoins;
        await seller.save();

        note.rewardedForApproval = true;

        try {
          await Notification.create({
            user: seller._id,
            title: '🪙 Coins Awarded!',
            message: `You earned ${rewardCoins} coins for uploading "${note.title}", which has been approved by the admin!`,
            type: 'Promo',
          });
        } catch (notifErr) {
          console.error('Failed to send coins award notification:', notifErr.message);
        }
      }
    }

    await note.save();

    res.status(200).json({ success: true, message: `Note status updated to ${status}`, data: note });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get notes accessible to the user (owned, purchased, or free)
// @route   GET /api/notes/my-library
// @access  Private
exports.getMyStudyNotes = async (req, res) => {
  try {
    const Order = require('../models/Order');
    const userId = req.user.id;

    // 1. Get IDs of notes purchased by the user
    const orders = await Order.find({ buyer: userId }).select('note');
    const purchasedNoteIds = orders.map(order => order.note);

    // 2. Fetch notes that match any of:
    //    - Note is owned by the user (seller === userId)
    //    - Note is purchased by the user (id in purchasedNoteIds)
    //    - Note is free (price === 0) and approved
    // And exclude physical items since AI features are only for study notes (Digital)
    const query = {
      itemType: 'Digital',
      $or: [
        { seller: userId },
        { _id: { $in: purchasedNoteIds } },
        { price: 0, status: 'Approved' }
      ]
    };

    const notes = await Note.find(query)
      .populate('seller', 'name email avatar college followers following addresses')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      count: notes.length,
      data: notes
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Get Reviews for Note
// @route   GET /api/notes/:id/reviews
// @access  Public
exports.getNoteReviews = async (req, res) => {
  try {
    const reviews = await Review.find({ note: req.params.id })
      .populate('user', 'name avatar')
      .sort({ createdAt: -1 });
    res.status(200).json({ success: true, data: reviews });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Report a Note
// @route   POST /api/notes/:id/report
// @access  Private
exports.reportNote = async (req, res) => {
  try {
    const { reason, details } = req.body;
    
    if (!reason) {
      return res.status(400).json({ success: false, message: 'Reason is required' });
    }

    const report = await Report.create({
      reporter: req.user.id,
      note: req.params.id,
      reason,
      details
    });

    res.status(201).json({ success: true, message: 'Report submitted successfully', data: report });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};

// @desc    Delete a note
// @route   DELETE /api/notes/:id
// @access  Private (Admin Only)
exports.deleteNote = async (req, res) => {
  try {
    const note = await Note.findById(req.params.id);
    if (!note) {
      return res.status(404).json({ success: false, message: 'Note not found' });
    }
    await note.deleteOne();
    res.status(200).json({ success: true, message: 'Note deleted successfully' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
};
