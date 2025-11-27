# Cloudinary Setup Guide

This app uses Cloudinary for free profile picture storage (10GB free tier).

## Setup Steps

1. **Create a Cloudinary Account**
   - Go to https://cloudinary.com/users/register/free
   - Sign up for a free account

2. **Get Your Cloud Name**
   - After signing up, go to your Dashboard
   - Your **Cloud Name** is displayed at the top (e.g., `dxyz123abc`)

3. **Create an Upload Preset**
   - Go to **Settings** → **Upload** → **Upload presets**
   - Click **Add upload preset**
   - Name it: `lyfstyl_profile_pictures` (or any name you prefer)
   - Set **Signing mode** to **Unsigned** (this allows client-side uploads)
   - Set **Folder** to: `lyfstyl/profiles` (optional, for organization)
   - Click **Save**

4. **Configure in Your App**

   For **local development**, create a `.env` file or set environment variables:
   ```bash
   CLOUDINARY_CLOUD_NAME=your_cloud_name_here
   CLOUDINARY_UPLOAD_PRESET=lyfstyl_profile_pictures
   ```

   For **Flutter web**, you can pass these as compile-time constants:
   ```bash
   flutter run -d chrome --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name --dart-define=CLOUDINARY_UPLOAD_PRESET=lyfstyl_profile_pictures
   ```

   For **production**, you can:
   - Store these in your build configuration
   - Use a config file (not recommended for client-side apps)
   - Or hardcode them temporarily (not recommended for security)

## Alternative: Hardcode for Quick Testing

If you want to test quickly, you can temporarily hardcode the values in `lib/services/firestore_service.dart`:

```dart
final cloudNameValue = cloudName ?? 'your_cloud_name_here';
final uploadPresetValue = uploadPreset ?? 'lyfstyl_profile_pictures';
```

**Note:** For production, use environment variables or a secure config approach.

## Free Tier Limits

- **Storage:** 10GB
- **Bandwidth:** 25GB/month
- **Transformations:** 25,000/month

This is more than enough for profile pictures! Each profile picture is typically 50-200KB, so you can store tens of thousands of images.

## Security Note

Using an **unsigned upload preset** means anyone with your preset name can upload images. This is fine for profile pictures since:
- Users can only upload their own profile picture
- Cloudinary will overwrite previous uploads with the same `public_id`
- The free tier has bandwidth limits that prevent abuse

For more security, you can use signed uploads with a server-side endpoint, but that requires backend setup.

