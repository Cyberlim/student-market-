const cloudinary = require('cloudinary').v2;

// Configure Cloudinary with environment variables
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

/**
 * Uploads a file buffer directly to Cloudinary using streams.
 * @param {Buffer} fileBuffer - The memory buffer of the file.
 * @param {string} [resourceType='auto'] - Type of resource: 'image', 'raw' (for PDF/ZIP), or 'auto'.
 * @returns {Promise<string>} - Resolves with the secure URL of the uploaded asset.
 */
const uploadToCloudinary = (fileBuffer, resourceType = 'auto') => {
  return new Promise((resolve, reject) => {
    // If Cloudinary environment parameters are not configured, log a warning and return undefined to use fallbacks
    if (!process.env.CLOUDINARY_CLOUD_NAME || !process.env.CLOUDINARY_API_KEY || !process.env.CLOUDINARY_API_SECRET) {
      console.warn('Cloudinary credentials not configured. Skipping upload to use defaults.');
      return resolve(null);
    }

    const uploadStream = cloudinary.uploader.upload_stream(
      { 
        resource_type: resourceType,
        use_filename: true,
        unique_filename: true,
        overwrite: false,
      },
      (error, result) => {
        if (error) {
          console.error('Cloudinary upload stream error:', error);
          return reject(error);
        }
        resolve(result.secure_url);
      }
    );
    
    uploadStream.end(fileBuffer);
  });
};

module.exports = {
  cloudinary,
  uploadToCloudinary,
};
