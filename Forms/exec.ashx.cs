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

namespace SqlUi
{

    public class exec : IHttpHandler
    {
        private const string loginRetry = "Please login and try again.";

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

            [JsonProperty("UserId")]
            public bool UserId { get; set; }

            [JsonProperty("Type")]
            public string Type { get; set; }

            public StoredProcedure()
            {
                this.JWT = null;
                this.Name = null;
                this.Parameters = new List<Parameter>();
                this.UserId = false;
                this.Type = "execute";
            }
        }

        private void ErrorResponse(HttpContext Context, SqlTransaction Transaction, int StatusCode, string Message)
        {
            Transaction.Rollback();
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
                        StoredProcedure Procedure;

                        try
                        {
                            using (StreamReader Reader = new StreamReader(Context.Request.InputStream, Encoding.UTF8))
                            {
                                Procedure = JsonConvert.DeserializeObject<StoredProcedure>(Reader.ReadToEnd());
                            }
                        }
                        catch { throw new InvalidDataException(); }

                        if (string.IsNullOrWhiteSpace(Procedure.JWT)) throw new UnauthorizedAccessException(loginRetry);

                        int UserId;
                        try
                        {
                            UserId = Security.UserIdFromToken(Procedure.JWT);
                            if (UserId <= 0) throw new UnauthorizedAccessException(loginRetry);
                        }
                        catch { throw new UnauthorizedAccessException(loginRetry); }

                        try
                        {
                            using (SqlCommand Command = new SqlCommand())
                            {
                                Command.Connection = Connection;
                                Command.Transaction = Transaction;
                                Command.CommandType = CommandType.StoredProcedure;
                                Command.CommandText = "apiUserVerify";
                                Command.Parameters.AddWithValue("UserId", UserId);
                                Command.Parameters.AddWithValue("Timeout", Convert.ToByte(WebConfigurationManager.AppSettings["LOGIN_TIMEOUT"]));
                                Command.ExecuteNonQuery();
                            }
                        }
                        catch (SqlException ex) { throw new UnauthorizedAccessException(ex.Message); }

                        using (SqlCommand Command = new SqlCommand())
                        {
                            Command.Connection = Connection;
                            Command.Transaction = Transaction;
                            Command.CommandType = CommandType.StoredProcedure;
                            Command.CommandText = Procedure.Name;
                            if (Procedure.UserId) Command.Parameters.AddWithValue("UserId", UserId);
                            foreach (Parameter Parameter in Procedure.Parameters)
                            {
                                if (Parameter.XML)
                                    Command.Parameters.AddWithValue(Parameter.Name, JsonConvert.DeserializeXmlNode(JsonConvert.SerializeObject(Parameter.Value), null, true).InnerXml);
                                else
                                    Command.Parameters.AddWithValue(Parameter.Name, Parameter.Value);
                            }
                            string Output;
                            if (Procedure.Type == "execute")
                            {
                                Command.ExecuteNonQuery();
                                Output = string.Empty;
                            }
                            else if (Procedure.Type == "object")
                            {
                                using (XmlReader Reader = Command.ExecuteXmlReader())
                                {
                                    XmlDocument Document = new XmlDocument();
                                    Document.Load(Reader);
                                    Output = JsonConvert.SerializeXmlNode(Document, Newtonsoft.Json.Formatting.Indented, false);
                                }
                            }
                            else
                            {
                                using (SqlDataReader Reader = Command.ExecuteReader((Procedure.Type == "singleton") ? CommandBehavior.SingleRow : CommandBehavior.SingleResult))
                                {
                                    using (DataTable Table = new DataTable())
                                    {
                                        Table.Load(Reader);
                                        Output = JsonConvert.SerializeObject(Table, Newtonsoft.Json.Formatting.Indented);
                                    }
                                }
                            }
                            Context.Response.ContentType = "text/json";
                            Context.Response.Write(Output);
                        }
                        Transaction.Commit();
                    }
                    catch (InvalidDataException ex) { ErrorResponse(Context, Transaction, 400, "Invalid data."); }
                    catch (UnauthorizedAccessException ex) { ErrorResponse(Context, Transaction, 401, ex.Message); }
                    catch (SqlException ex) { ErrorResponse(Context, Transaction, 531, ex.Message); }
                    catch (Exception ex) { ErrorResponse(Context, Transaction, 500, ex.Message); }
                }
                Connection.Close();
            }
        }

        public bool IsReusable { get { return false; } }

    }

}