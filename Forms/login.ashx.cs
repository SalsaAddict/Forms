using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.IO;
using System.Text;
using System.Data;
using System.Data.SqlClient;
using System.Web.Configuration;
using JWT;

namespace MG
{

    public class login : IHttpHandler
    {

        private class MGLogin
        {
            [JsonProperty("Email")]
            public string Email { get; set; }

            [JsonProperty("Password")]
            public string Password { get; set; }
        }

        private class MGUser
        {
            [JsonProperty("UserId")]
            public int UserId { get; set; }

            [JsonProperty("Forename")]
            public string Forename { get; set; }

            [JsonProperty("Surname")]
            public string Surname { get; set; }

            [JsonProperty("Reset")]
            public bool Reset { get; set; }
        }

        private class MGResult
        {
            [JsonProperty("Validated")]
            public bool Validated { get; set; }

            [JsonProperty("JWT")]
            public string JWT { get; set; }

            [JsonProperty("User")]
            public MGUser User { get; set; }

            public MGResult()
            {
                this.Validated = false;
                this.JWT = null;
                this.User = null;
            }
        }

        public void ProcessRequest(HttpContext Context)
        {
            MGResult Result = new MGResult();
            using (SqlConnection Connection = new SqlConnection(WebConfigurationManager.ConnectionStrings["Database"].ConnectionString))
            {
                Connection.Open();
                using (SqlTransaction Transaction = Connection.BeginTransaction(IsolationLevel.Serializable))
                {
                    try
                    {
                        using (SqlCommand Command = new SqlCommand())
                        {
                            MGLogin Login;
                            using (StreamReader Reader = new StreamReader(Context.Request.InputStream, Encoding.UTF8))
                            {
                                Login = JsonConvert.DeserializeObject<MGLogin>(Reader.ReadToEnd());
                                Reader.Close();
                            }
                            Command.Connection = Connection;
                            Command.Transaction = Transaction;
                            Command.CommandType = CommandType.StoredProcedure;
                            Command.CommandText = "apiUser";
                            Command.Parameters.AddWithValue("Email", Login.Email);
                            using (SqlDataReader Reader = Command.ExecuteReader(CommandBehavior.SingleRow))
                            {
                                if (Reader.HasRows)
                                {
                                    Reader.Read();
                                    if (PasswordHash.ValidatePassword(Login.Password, Reader.GetString(Reader.GetOrdinal("Password"))))
                                    {
                                        Result.User = new MGUser();
                                        Result.User.UserId = Reader.GetInt32(Reader.GetOrdinal("UserId"));
                                        Result.User.Forename = Reader.GetString(Reader.GetOrdinal("Forename"));
                                        Result.User.Surname = Reader.GetString(Reader.GetOrdinal("Surname"));
                                        Result.User.Reset = Reader.GetBoolean(Reader.GetOrdinal("Reset"));
                                        Result.JWT = JsonWebToken.Encode(Result.User, WebConfigurationManager.AppSettings["JWTEncryptionKey"], JwtHashAlgorithm.HS512);
                                        Result.Validated = true;

                                    }
                                }
                            }
                        }
                        Transaction.Commit();
                    }
                    catch (Exception ex) { }
                }
                Connection.Close();
            }
            Context.Response.ContentType = "text/json";
            Context.Response.Write(JsonConvert.SerializeObject(Result, Newtonsoft.Json.Formatting.Indented));
        }

        public bool IsReusable { get { return false; } }

    }

}