using System;
using System.Runtime.InteropServices;

#if NETFRAMEWORK
using AssetStudio.PInvoke;
#endif

namespace Texture2DDecoder
{
    public static unsafe partial class TextureDecoder
    {

        static TextureDecoder()
        {
#if NETFRAMEWORK
            DllLoader.PreloadDll(T2DDll.DllName);
#endif
        }

        public static bool DecodeDXT1(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeDXT1(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodeDXT5(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeDXT5(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodePVRTC(ReadOnlySpan<byte> data, int width, int height, Span<byte> image, bool is2bpp)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodePVRTC(pData, width, height, pImage, is2bpp);
                }
            }
        }

        public static bool DecodeETC1(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeETC1(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodeETC2(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeETC2(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodeETC2A1(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeETC2A1(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodeETC2A8(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeETC2A8(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodeEACR(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeEACR(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodeEACRSigned(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeEACRSigned(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodeEACRG(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeEACRG(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodeEACRGSigned(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeEACRGSigned(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodeBC4(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeBC4(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodeBC5(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeBC5(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodeBC6(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeBC6(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodeBC7(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeBC7(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodeATCRGB4(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeATCRGB4(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodeATCRGBA8(ReadOnlySpan<byte> data, int width, int height, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeATCRGBA8(pData, width, height, pImage);
                }
            }
        }

        public static bool DecodeASTC(ReadOnlySpan<byte> data, int width, int height, int blockWidth, int blockHeight, Span<byte> image)
        {
            fixed (byte* pData = data)
            {
                fixed (byte* pImage = image)
                {
                    return DecodeASTC(pData, width, height, blockWidth, blockHeight, pImage);
                }
            }
        }

        public static byte[] UnpackCrunch(ReadOnlySpan<byte> data)
        {
            void* pBuffer;
            uint bufferSize;

            fixed (byte* pData = data)
            {
                UnpackCrunch(pData, (uint)data.Length, out pBuffer, out bufferSize);
            }

            if (pBuffer == null)
            {
                return null;
            }

            var result = new byte[bufferSize];

            Marshal.Copy(new IntPtr(pBuffer), result, 0, (int)bufferSize);

            DisposeBuffer(ref pBuffer);

            return result;
        }

        public static byte[] UnpackUnityCrunch(ReadOnlySpan<byte> data)
        {
            void* pBuffer;
            uint bufferSize;

            fixed (byte* pData = data)
            {
                UnpackUnityCrunch(pData, (uint)data.Length, out pBuffer, out bufferSize);
            }

            if (pBuffer == null)
            {
                return null;
            }

            var result = new byte[bufferSize];

            Marshal.Copy(new IntPtr(pBuffer), result, 0, (int)bufferSize);

            DisposeBuffer(ref pBuffer);

            return result;
        }

    }
}
