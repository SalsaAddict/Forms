using Newtonsoft.Json;
using System;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Configuration;

namespace SqlUi
{

    public class login : IHttpHandler
    {

        private class LoginRequest
        {
            [JsonProperty("Email")]
            public string Email { get; set; }

            [JsonProperty("Password")]
            public string Password { get; set; }
        }

        private class LoginResponse
        {
            [JsonProperty("Validated")]
            public bool Validated { get; set; }

            [JsonProperty("Reset")]
            public bool Reset { get; set; }

            [JsonProperty("JWT")]
            public string JWT { get; set; }

            [JsonProperty("Error")]
            public string Error { get; set; }

            public LoginResponse()
            {
                this.Validated = false;
                this.Reset = false;
                this.JWT = string.Empty;
            }
        }

        public void ProcessRequest(HttpContext Context)
        {
            LoginResponse Response = new LoginResponse();
            try
            {
                using (SqlConnection Connection = new SqlConnection(WebConfigurationManager.ConnectionStrings["Database"].ConnectionString))
                {
                    Connection.Open();
                    using (SqlTransaction Transaction = Connection.BeginTransaction(IsolationLevel.ReadUncommitted))
                    {
                        using (SqlCommand Command = new SqlCommand())
                        {
                            LoginRequest Request;
                            using (StreamReader Reader = new StreamReader(Context.Request.InputStream, Encoding.UTF8))
                            {
                                Request = JsonConvert.DeserializeObject<LoginRequest>(Reader.ReadToEnd());
                                Reader.Close();
                            }
                            Command.Connection = Connection;
                            Command.Transaction = Transaction;
                            Command.CommandType = CommandType.StoredProcedure;
                            Command.CommandText = "apiUserLogin";
                            Command.Parameters.AddWithValue("Email", Request.Email);
                            using (SqlDataReader Reader = Command.ExecuteReader(CommandBehavior.SingleRow))
                            {
                                if (Reader.HasRows)
                                {
                                    Reader.Read();
                                    if (Security.ValidatePassword(Request.Password, Reader.GetString(Reader.GetOrdinal("Password"))))
                                    {
                                        Response.Validated = true;
                                        Response.Reset = Reader.GetBoolean(Reader.GetOrdinal("Reset"));
                                        Response.JWT = Security.Token(Reader.GetInt32(Reader.GetOrdinal("UserId")));
                                    }
                                }
                                Reader.Close();
                            }
                        }
                        Transaction.Commit();
                    }
                    Connection.Close();
                }
            }
            catch (Exception ex) { Response = new LoginResponse(); }
            Context.Response.ContentType = "text/json";
            Context.Response.Write(JsonConvert.SerializeObject(Response, Newtonsoft.Json.Formatting.Indented));
        }

        public bool IsReusable { get { return false; } }

    }

}