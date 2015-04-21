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
                        StoredProcedure Procedure;

                        try
                        {
                            using (StreamReader Reader = new StreamReader(Context.Request.InputStream, Encoding.UTF8))
                            {
                                Procedure = JsonConvert.DeserializeObject<StoredProcedure>(Reader.ReadToEnd());
                            }
                        }
                        catch { throw new UnauthorizedAccessException(loginRetry); }

                        if (string.IsNullOrWhiteSpace(Procedure.JWT))
                            throw new UnauthorizedAccessException(loginRetry);

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
                            if (Procedure.Parameters != null)
                            {
                                foreach (Parameter Parameter in Procedure.Parameters)
                                {
                                    if (Parameter.XML)
                                        Command.Parameters.AddWithValue(Parameter.Name, JsonConvert.DeserializeXmlNode(JsonConvert.SerializeObject(Parameter.Value), null, true).InnerXml);
                                    else
                                        Command.Parameters.AddWithValue(Parameter.Name, Parameter.Value);
                                }
                            }
                            using (SqlDataReader Reader = Command.ExecuteReader(CommandBehavior.SingleResult))
                            {
                                string Output;
                                if (Reader.FieldCount == 1 && Reader.GetDataTypeName(0) == "xml")
                                {
                                    XmlDocument Document = new XmlDocument();
                                    Document.Load(Reader.GetXmlReader(0));
                                    Output = JsonConvert.SerializeXmlNode(Document, Newtonsoft.Json.Formatting.Indented, false);
                                }
                                else
                                {
                                    using (DataTable Table = new DataTable())
                                    {
                                        Table.Load(Reader);
                                        Output = JsonConvert.SerializeObject(Table, Newtonsoft.Json.Formatting.Indented);
                                    }
                                }
                                Context.Response.ContentType = "text/json";
                                Context.Response.Write(Output);
                            }
                        }
                        Transaction.Commit();
                    }
                    catch (UnauthorizedAccessException ex)
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