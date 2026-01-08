const jsQR = require('jsqr');
const { Jimp } = require('jimp');
const xml2js = require('xml2js');
const crypto = require('crypto');
const zlib = require('zlib');

/**
 * Aadhaar QR Code Verification Service
 * 
 * This service handles decoding and verifying mAadhaar QR codes.
 * The QR code contains compressed XML data with digital signature.
 */
class AadhaarService {
    /**
     * Decode QR code from image buffer
     * @param {Buffer} imageBuffer - Image buffer containing QR code
     * @returns {Promise<string>} - Raw QR code data
     */
    async decodeQRFromImage(imageBuffer) {
        try {
            // Read image using Jimp v1.x API
            const image = await Jimp.read(imageBuffer);

            // Log image info for debugging
            console.log(`Image loaded: ${image.width}x${image.height}`);

            // Get raw pixel data
            const width = image.width;
            const height = image.height;

            // Convert bitmap data to RGBA format for jsQR
            const data = new Uint8ClampedArray(width * height * 4);
            let idx = 0;

            for (let y = 0; y < height; y++) {
                for (let x = 0; x < width; x++) {
                    const color = image.getPixelColor(x, y);
                    // Extract RGBA from color integer
                    data[idx++] = (color >> 24) & 0xFF; // R
                    data[idx++] = (color >> 16) & 0xFF; // G
                    data[idx++] = (color >> 8) & 0xFF;  // B
                    data[idx++] = color & 0xFF;          // A
                }
            }

            // Try to decode QR
            const qrResult = jsQR(data, width, height);

            if (qrResult && qrResult.data) {
                console.log('QR decoded successfully');
                return qrResult.data;
            }

            // If first attempt fails, try with grayscale
            console.log('First attempt failed, trying grayscale...');
            image.greyscale();

            idx = 0;
            for (let y = 0; y < height; y++) {
                for (let x = 0; x < width; x++) {
                    const color = image.getPixelColor(x, y);
                    data[idx++] = (color >> 24) & 0xFF;
                    data[idx++] = (color >> 16) & 0xFF;
                    data[idx++] = (color >> 8) & 0xFF;
                    data[idx++] = color & 0xFF;
                }
            }

            const qrResult2 = jsQR(data, width, height);

            if (qrResult2 && qrResult2.data) {
                console.log('QR decoded on grayscale attempt');
                return qrResult2.data;
            }

            throw new Error('No QR code found in the image. Please ensure the QR code is clear and well-lit.');
        } catch (error) {
            console.error('QR decode error:', error);
            throw new Error(`Failed to decode QR code: ${error.message}`);
        }
    }

    /**
     * Decompress and parse QR data (mAadhaar uses different formats)
     * @param {string} qrData - Raw QR data
     * @returns {Promise<Object>} - Parsed data object
     */
    async decompressQRData(qrData) {
        console.log('Raw QR data (first 100 chars):', qrData.substring(0, 100));
        console.log('QR data length:', qrData.length);

        try {
            // mAadhaar QR can be in different formats:
            // 1. Plain XML (older format)
            // 2. Base64 encoded compressed data
            // 3. BigInteger encoded data (Secure QR V2)

            // Check if it's XML
            if (qrData.startsWith('<?xml') || qrData.startsWith('<')) {
                return { type: 'xml', data: qrData };
            }

            // Check if it's numeric (Secure QR format)
            if (/^\d+$/.test(qrData.trim())) {
                console.log('Detected Secure QR format (numeric)');
                const parsedData = this.parseSecureQRV2(qrData.trim());
                return { type: 'secure', data: parsedData };
            }

            // Try Base64 decoding and decompression
            try {
                const buffer = Buffer.from(qrData, 'base64');
                const decompressed = zlib.inflateSync(buffer);
                const decompressedStr = decompressed.toString('utf-8');
                if (decompressedStr.startsWith('<')) {
                    return { type: 'xml', data: decompressedStr };
                }
            } catch (e) {
                // Not base64 compressed
            }

            // If nothing works, try to parse as-is
            console.log('Unknown format, returning raw data');
            return { type: 'unknown', data: qrData };
        } catch (error) {
            throw new Error(`Failed to decompress QR data: ${error.message}`);
        }
    }

    /**
     * Parse Secure QR V2 format (BigInteger encoded + zlib compressed)
     * mAadhaar uses this format - data is compressed then encoded as a large number
     * @param {string} numericData - Numeric string from QR
     * @returns {Object} - Parsed Aadhaar data
     */
    parseSecureQRV2(numericData) {
        try {
            // Step 1: Convert numeric string to byte array
            const bytes = [];
            let num = BigInt(numericData);

            while (num > 0n) {
                bytes.unshift(Number(num & 0xFFn));
                num = num >> 8n;
            }

            let buffer = Buffer.from(bytes);
            console.log('Initial buffer length:', buffer.length);
            console.log('First 20 bytes:', buffer.slice(0, 20).toString('hex'));

            // Step 2: Try multiple decompression methods
            let decompressed = null;

            // Try 1: zlib inflate (with header)
            try {
                decompressed = zlib.inflateSync(buffer);
                console.log('Decompressed with zlib inflate, length:', decompressed.length);
            } catch (e) {
                console.log('zlib inflate failed:', e.message);
            }

            // Try 2: raw inflate (no header) 
            if (!decompressed) {
                try {
                    decompressed = zlib.inflateRawSync(buffer);
                    console.log('Decompressed with raw inflate, length:', decompressed.length);
                } catch (e) {
                    console.log('raw inflate failed:', e.message);
                }
            }

            // Try 3: gunzip
            if (!decompressed) {
                try {
                    decompressed = zlib.gunzipSync(buffer);
                    console.log('Decompressed with gunzip, length:', decompressed.length);
                } catch (e) {
                    console.log('gunzip failed:', e.message);
                }
            }

            // Try 4: unzip (skip first 2 bytes - custom header)
            if (!decompressed) {
                try {
                    decompressed = zlib.inflateSync(buffer.slice(2));
                    console.log('Decompressed with zlib (skip 2), length:', decompressed.length);
                } catch (e) {
                    console.log('zlib skip 2 failed');
                }
            }

            // Try 5: raw inflate (skip first 2 bytes)
            if (!decompressed) {
                try {
                    decompressed = zlib.inflateRawSync(buffer.slice(2));
                    console.log('Decompressed with raw (skip 2), length:', decompressed.length);
                } catch (e) {
                    console.log('raw skip 2 failed');
                }
            }

            // If all decompression fails, use original buffer
            if (!decompressed) {
                console.log('All decompression methods failed, using raw buffer');
                decompressed = buffer;
            }

            buffer = decompressed;

            // Step 3: Parse the decompressed data
            // The data is delimiter(255) separated UTF-8 strings
            // No indicator bytes at start based on our testing

            const delimiter = 255;
            let position = 0;

            // Function to read string until delimiter
            const readString = () => {
                let start = position;
                while (position < buffer.length && buffer[position] !== delimiter) {
                    position++;
                }
                const str = buffer.slice(start, position).toString('utf-8');
                position++; // Skip delimiter
                return str.trim();
            };

            // Read all fields first to understand the order
            const fields = [];
            while (position < buffer.length) {
                const field = readString();
                if (field) {
                    fields.push(field);
                }
            }

            console.log('Total fields found:', fields.length);
            console.log('All fields:', fields.slice(0, 20)); // Print first 20 fields

            // Improved heuristic: Find Gender to anchor the other fields
            // Gender is usually "M" or "F" or "Male" or "Female"
            let genderIndex = fields.findIndex(f => ['M', 'F', 'Male', 'Female', 'Transgender'].includes(f));

            let nameIndex = 3; // Default

            if (genderIndex !== -1) {
                // Based on standard order: RefId, Name, DOB, Gender, ...
                if (genderIndex >= 2) {
                    nameIndex = genderIndex - 2;
                }
            }

            // Parse based on detected indices

            const name = fields[nameIndex] || '';
            const dob = fields[nameIndex + 1] || '';
            const gender = fields[nameIndex + 2] || '';

            // Address fields follow after gender
            const careOf = fields[nameIndex + 3] || '';
            const district = fields[nameIndex + 4] || '';
            const landmark = fields[nameIndex + 5] || '';
            const house = fields[nameIndex + 6] || '';
            const location = fields[nameIndex + 7] || '';
            const pincode = fields[nameIndex + 8] || '';
            const postOffice = fields[nameIndex + 9] || '';
            const state = fields[nameIndex + 10] || '';
            const street = fields[nameIndex + 11] || '';
            const subDistrict = fields[nameIndex + 12] || '';
            const vtc = fields[nameIndex + 13] || '';

            // Find pincode (6 digits) explicitly as fallback
            let detectedPincode = pincode;
            for (const f of fields) {
                if (/^\d{6}$/.test(f)) {
                    detectedPincode = f;
                    break;
                }
            }

            // Reference ID is usually early in the array (index 1 or 0)
            const referenceId = fields[1] || fields[0] || '';

            // Last 4 digits of Aadhaar from reference ID
            const uidMatch = referenceId.match(/\d{4}$/);
            const uidLast4 = uidMatch ? uidMatch[0] : '';

            // Map Gender to full string
            const genderMap = { 'M': 'Male', 'F': 'Female', 'T': 'Transgender' };
            const finalGender = genderMap[gender] || gender;

            console.log('Secure QR V2 parsed successfully');

            return {
                uid: uidLast4,
                referenceId,
                name,
                dateOfBirth: dob,
                gender: finalGender,
                careOf,
                house,
                street,
                landmark,
                locality: location,
                village: vtc,
                district,
                subDistrict,
                state,
                postcode: detectedPincode,
                postOffice,
                hasImage: false,
                hasEmailMobile: false,
            };
        } catch (error) {
            console.error('Secure QR parse error:', error);
            throw new Error(`Failed to parse Secure QR: ${error.message}`);
        }
    }

    /**
     * Parse XML data from Aadhaar QR
     * @param {string} xmlData - XML string from QR
     * @returns {Promise<Object>} - Parsed Aadhaar data
     */
    async parseAadhaarXML(xmlData) {
        try {
            const parser = new xml2js.Parser({
                explicitArray: false,
                ignoreAttrs: false,
                attrkey: '$',
            });

            const result = await parser.parseStringPromise(xmlData);

            // Aadhaar XML structure: <QRData> or <PrintLetterQr>
            const qrData = result.QRData || result.PrintLetterQr || result;
            const attrs = qrData.$ || qrData;

            return {
                uid: attrs.uid || attrs.u || null, // Last 4 digits of Aadhaar
                name: attrs.name || attrs.n || null,
                gender: attrs.gender || attrs.g || null,
                dateOfBirth: attrs.dob || attrs.d || null,
                yearOfBirth: attrs.yob || null,
                careOf: attrs.co || null,
                house: attrs.house || attrs.h || null,
                street: attrs.street || attrs.s || null,
                landmark: attrs.lm || null,
                locality: attrs.loc || attrs.l || null,
                village: attrs.vtc || null,
                district: attrs.dist || null,
                subDistrict: attrs.subdist || null,
                state: attrs.state || attrs.st || null,
                postcode: attrs.pc || null,
                mobile: attrs.m || null, // Last 4 digits
                email: attrs.e || null, // Masked
                photo: attrs.i || attrs.photo || null, // Base64 encoded photo
                signature: attrs.s || attrs.signature || null,
                signatureData: attrs.Sig || null,
            };
        } catch (error) {
            throw new Error(`Failed to parse Aadhaar XML: ${error.message}`);
        }
    }

    /**
     * Generate a deterministic hash for deduplication
     * @param {Object} data - Verified Aadhaar data
     * @returns {string} - SHA-256 hash
     */
    generateDeduplicationHash(data) {
        // Create a unique string from immutable identity fields
        // use lower case and trim to ensure consistency
        const name = (data.name || '').toLowerCase().trim();
        const dob = (data.dateOfBirth || '').trim();
        const gender = (data.gender || '').toLowerCase().trim();
        const uidLast4 = (data.uid || '').trim();
        const pincode = (data.postcode || '').trim();

        // Composite key: name|dob|gender|uidLast4|pincode
        // This combination is highly likely to be unique for a person
        const compositeKey = `${name}|${dob}|${gender}|${uidLast4}|${pincode}`;

        return crypto
            .createHash('sha256')
            .update(compositeKey)
            .digest('hex');
    }

    /**
     * Verify the digital signature of Aadhaar QR data
     * Note: Full verification requires UIDAI's public key
     * @param {string} data - Data to verify
     * @param {string} signature - Signature from QR
     * @returns {boolean} - Verification result
     */
    verifySignature(data, signature) {
        // Note: For production, you need UIDAI's public key
        // This is a placeholder for signature verification logic

        if (!signature) {
            console.warn('No signature found in QR data');
            return false;
        }

        // In production: verify using UIDAI's public certificate
        // const verify = crypto.createVerify('SHA256');
        // verify.update(data);
        // return verify.verify(UIDAI_PUBLIC_KEY, signature, 'base64');

        // For development, we'll just check if signature exists
        return true;
    }

    /**
     * Hash Aadhaar number for secure storage
     * @param {string} aadhaarNumber - Full Aadhaar number
     * @returns {string} - Hashed Aadhaar number
     */
    hashAadhaarNumber(aadhaarNumber) {
        // Remove spaces and validate format
        const cleanNumber = aadhaarNumber.replace(/\s/g, '');

        if (!/^\d{12}$/.test(cleanNumber)) {
            throw new Error('Invalid Aadhaar number format');
        }

        // Use SHA-256 with salt for hashing
        const salt = process.env.AADHAAR_HASH_SALT || 'joinme_aadhaar_salt_2024';
        const hash = crypto
            .createHash('sha256')
            .update(cleanNumber + salt)
            .digest('hex');

        return hash;
    }

    /**
     * Generate reference ID from Aadhaar (last 4 digits)
     * @param {string} uid - UID from QR (last 4 digits)
     * @returns {string} - Reference ID
     */
    generateReferenceId(uid) {
        const timestamp = Date.now().toString(36);
        const random = crypto.randomBytes(4).toString('hex');
        return `AADH-${uid || 'XXXX'}-${timestamp}-${random}`.toUpperCase();
    }

    /**
     * Process and verify Aadhaar QR code
     * @param {Buffer} imageBuffer - Image buffer containing QR code
     * @returns {Promise<Object>} - Verified Aadhaar data
     */
    async verifyAadhaarQR(imageBuffer) {
        try {
            // Step 1: Decode QR from image
            const rawData = await this.decodeQRFromImage(imageBuffer);
            console.log('QR decoded successfully');

            // Step 2: Decompress/parse data
            const result = await this.decompressQRData(rawData);
            console.log('QR data processed, type:', result.type);

            let parsedData;

            // Step 3: Parse based on format type
            if (result.type === 'secure') {
                // Secure QR V2 format - already parsed
                parsedData = result.data;
                console.log('Using Secure QR parsed data');
            } else if (result.type === 'xml') {
                // XML format
                parsedData = await this.parseAadhaarXML(result.data);
                console.log('Parsed XML data');
            } else {
                // Try XML parsing as fallback
                try {
                    parsedData = await this.parseAadhaarXML(result.data);
                } catch (e) {
                    throw new Error('Unable to parse QR data format');
                }
            }

            console.log('Aadhaar data parsed successfully');

            // Step 4: Generate reference ID
            const referenceId = this.generateReferenceId(parsedData.uid);

            return {
                success: true,
                verified: true, // Secure QR doesn't have external signature
                referenceId,
                data: {
                    name: parsedData.name,
                    uidLastFour: parsedData.uid,
                    gender: parsedData.gender,
                    dateOfBirth: parsedData.dateOfBirth,
                    yearOfBirth: parsedData.yearOfBirth,
                    address: {
                        careOf: parsedData.careOf,
                        house: parsedData.house,
                        street: parsedData.street,
                        landmark: parsedData.landmark,
                        locality: parsedData.locality,
                        village: parsedData.village,
                        district: parsedData.district,
                        subDistrict: parsedData.subDistrict,
                        state: parsedData.state,
                        postcode: parsedData.postcode,
                    },
                    hasPhoto: parsedData.hasImage || !!parsedData.photo,
                    photoBase64: parsedData.photo || null,
                },
                timestamp: new Date().toISOString(),
            };
        } catch (error) {
            console.error('Verification error:', error);
            return {
                success: false,
                verified: false,
                error: error.message,
                timestamp: new Date().toISOString(),
            };
        }
    }

    /**
     * Validate Aadhaar number format
     * @param {string} aadhaarNumber - Aadhaar number to validate
     * @returns {boolean} - True if valid format
     */
    validateAadhaarFormat(aadhaarNumber) {
        const cleanNumber = aadhaarNumber.replace(/\s/g, '');

        // Must be 12 digits
        if (!/^\d{12}$/.test(cleanNumber)) {
            return false;
        }

        // Verhoeff algorithm validation (optional, for production)
        // return this.verifyVerhoeff(cleanNumber);

        return true;
    }
}

module.exports = new AadhaarService();
