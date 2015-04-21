using Newtonsoft.Json;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using System.Text;
using System.Web;
using System.Web.Configuration;
using System.Xml;

namespace MG
{

    public class exec : IHttpHandler
    {

        private class Parameter
        {
            [JsonProperty("Name")]
            public string Name { get; set; }

            [JsonProperty("Value")]
            public object Value { get; set; }

            [JsonProperty("XML")]
            public bool XML { get; set; }
        }

        private class StoredProcedure
        {
            [JsonProperty("JWT")]
            public string JWT { get; set; }

            [JsonProperty("Name")]
            public string Name { get; set; }

            [JsonProperty("Parameters")]
            public List<Parameter> Parameters { get; set; }
        }

        private void ErrorResponse(HttpContext Context, int StatusCode, string Message)
        {
            Context.Response.Clear();
            Context.Response.ContentType = "text/plain";
            Context.Response.Write(Message);
            Context.Response.StatusCode = StatusCode;
            Context.Response.End();
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
                        StoredProcedure Input;
                        using (StreamReader Reader = new StreamReader(Context.Request.InputStream, Encoding.UTF8))
                        {
                            Input = JsonConvert.DeserializeObject<StoredProcedure>(Reader.ReadToEnd());
                            Reader.Close();
                        }
                        if (string.IsNullOrWhiteSpace(Input.JWT)) throw new UnauthorizedAccessException("Missing token.");
                        using (SqlCommand Command = new SqlCommand())
                        {
                            Command.Connection = Connection;
                            Command.Transaction = Transaction;
                            Command.CommandType = CommandType.StoredProcedure;
                            Command.CommandText = "apiUserVerify";
                            Command.Parameters.AddWithValue("UserId", Security.UserIdFromToken(Input.JWT));
                            Command.ExecuteNonQuery();
                        }
                        using (SqlCommand Command = new SqlCommand())
                        {
                            Command.Connection = Connection;
                            Command.Transaction = Transaction;
                            Command.CommandType = CommandType.StoredProcedure;
                            Command.CommandText = Input.Name;
                            if (Input.Parameters != null)
                            {
                                foreach (Parameter Parameter in Input.Parameters)
                                {
                                    if (Parameter.XML)
                                        Command.Parameters.AddWithValue(Parameter.Name, JsonConvert.DeserializeXmlNode(JsonConvert.SerializeObject(Parameter.Value), null, true).InnerXml);
                                    else
                                        Command.Parameters.AddWithValue(Parameter.Name, Parameter.Value);
                                }
                            }
                            bool ReturnsXml;
                            if (!bool.TryParse(Context.Request.QueryString["rx"], out ReturnsXml)) ReturnsXml = false;
                            if (ReturnsXml)
                            {
                                using (XmlReader Reader = Command.ExecuteXmlReader())
                                {
                                    XmlDocument Document = new XmlDocument();
                                    Document.Load(Reader);
                                    Reader.Close();
                                    string Output = JsonConvert.SerializeXmlNode(Document, Newtonsoft.Json.Formatting.Indented, false);
                                    Context.Response.ContentType = "text/json";
                                    Context.Response.Write(Output);
                                }
                            }
                            else
                            {
                                using (SqlDataReader Reader = Command.ExecuteReader(CommandBehavior.SingleResult))
                                {
                                    using (DataTable Table = new DataTable())
                                    {
                                        Table.Load(Reader);
                                        string Output = JsonConvert.SerializeObject(Table, Newtonsoft.Json.Formatting.Indented);
                                        Context.Response.ContentType = "text/json";
                                        Context.Response.Write(Output);
                                    }
                                }
                            }
                        }
                        Transaction.Commit();
                    }
                    catch (UnauthorizedAccessException ex)
                    {
                        Transaction.Rollback();
                        ErrorResponse(Context, 401, ex.Message);
                    }
                    catch (JWT.SignatureVerificationException ex)
                    {
                        Transaction.Rollback();
                        ErrorResponse(Context, 401, ex.Message);
                    }
                    catch (Exception ex)
                    {
                        Transaction.Rollback();
                        ErrorResponse(Context, 400, ex.Message);
                    }
                }
                Connection.Close();
            }
        }

        public bool IsReusable { get { return false; } }

    }

}