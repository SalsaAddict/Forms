using System;
using System.Security.Cryptography;
using System.Web.Configuration;
using JWT;
using Newtonsoft.Json;

namespace MG
{

    public class Payload
    {
        public int UserId { get; set; }

        public int exp { get; set; }

        public Payload() { }

        public Payload(int UserId)
        {
            int minutes = Convert.ToInt32(WebConfigurationManager.AppSettings["JWT_EXPIRY_MINUTES"]);
            this.UserId = UserId;
            this.exp = Convert.ToInt32(Math.Round((DateTime.UtcNow.AddMinutes(minutes) - new DateTime(1970, 1, 1, 0, 0, 0, DateTimeKind.Utc)).TotalSeconds, 0));
        }
    }

    public static class Security
    {

        public static byte[] GenerateSalt()
        {
            RNGCryptoServiceProvider rng = new RNGCryptoServiceProvider();
            byte[] salt = new byte[Convert.ToInt32(WebConfigurationManager.AppSettings["SALT_BYTE_SIZE"])];
            rng.GetBytes(salt);
            return salt;
        }

        public static string HashPassword(string password)
        {
            byte[] salt = GenerateSalt();
            int iterations = Convert.ToInt32(WebConfigurationManager.AppSettings["PBKDF2_ITERATIONS"]);
            int hashByteSize = Convert.ToInt32(WebConfigurationManager.AppSettings["HASH_BYTE_SIZE"]);
            byte[] hash = PBKDF2(password, salt, iterations, hashByteSize);
            return string.Format("{0}:{1}:{2}", iterations, Convert.ToBase64String(salt), Convert.ToBase64String(hash));
        }

        public static bool ValidatePassword(string password, string hashedPassword)
        {
            string[] split = hashedPassword.Split(":".ToCharArray());
            int iterations = Int32.Parse(split[0]);
            byte[] salt = Convert.FromBase64String(split[1]);
            byte[] hash = Convert.FromBase64String(split[2]);
            byte[] testHash = PBKDF2(password, salt, iterations, hash.Length);
            return SlowEquals(hash, testHash);
        }

        private static bool SlowEquals(byte[] a, byte[] b)
        {
            uint diff = (uint)a.Length ^ (uint)b.Length;
            for (int i = 0; i < a.Length && i < b.Length; i++)
                diff |= (uint)(a[i] ^ b[i]);
            return diff == 0;
        }

        private static byte[] PBKDF2(string password, byte[] salt, int iterations, int outputBytes)
        {
            Rfc2898DeriveBytes pbkdf2 = new Rfc2898DeriveBytes(password, salt);
            pbkdf2.IterationCount = iterations;
            return pbkdf2.GetBytes(outputBytes);
        }

        public static string Token(int UserId)
        {
            string key = WebConfigurationManager.AppSettings["JWT_ENCRYPTION_KEY"];
            return JsonWebToken.Encode(new Payload(UserId), key, JwtHashAlgorithm.HS512);
        }

        public static int UserIdFromToken(string Token)
        {
            string key = WebConfigurationManager.AppSettings["JWT_ENCRYPTION_KEY"];
            Payload Payload = JsonWebToken.DecodeToObject<Payload>(Token, key, true);
            return Payload.UserId;
        }

    }

}