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

namespace mg
{

    public class login : IHttpHandler
    {

        private class Credentials
        {
            [JsonProperty("Email")]
            public string Email { get; set; }

            [JsonProperty("Password")]
            public string Password { get; set; }
        }

        public void ProcessRequest(HttpContext Context)
        {
            using (SqlConnection Connection = new SqlConnection(WebConfigurationManager.ConnectionStrings["Database"].ConnectionString))
            {
                Connection.Open();
                using (SqlTransaction Transaction = Connection.BeginTransaction(IsolationLevel.Serializable))
                {
                    try
                    {
                        using (SqlCommand Command = new SqlCommand())
                        {
                            Credentials Login;
                            using (StreamReader Reader = new StreamReader(Context.Request.InputStream, Encoding.UTF8))
                            {
                                Login = JsonConvert.DeserializeObject<Credentials>(Reader.ReadToEnd());
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
                                }
                            }
                        }
                        Transaction.Commit();
                    }
                    catch (Exception ex)
                    {
                        Transaction.Rollback();
                        Context.Response.Clear();
                        Context.Response.ContentType = "text/plain";
                        Context.Response.Write(ex.Message);
                        Context.Response.StatusCode = 400;
                        Context.Response.End();
                    }
                }
                Connection.Close();
            }
        }

        public bool IsReusable { get { return false; } }

    }

}