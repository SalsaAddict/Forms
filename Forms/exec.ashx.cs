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

namespace Forms
{

    public class exec : IHttpHandler
    {

        private class Parameter
        {
            [JsonProperty("Name")]
            public string Name { get; set; }

            [JsonProperty("Value")]
            public string Value { get; set; }
        }

        private class StoredProcedure
        {
            [JsonProperty("Name")]
            public string Name { get; set; }

            [JsonProperty("Parameters")]
            public List<Parameter> Parameters { get; set; }

            [JsonProperty("XML")]
            public object Xml { get; set; }
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
                            StoredProcedure Input;
                            using (StreamReader Reader = new StreamReader(Context.Request.InputStream, Encoding.UTF8))
                            {
                                Input = JsonConvert.DeserializeObject<StoredProcedure>(Reader.ReadToEnd());
                                Reader.Close();
                            }
                            Command.Connection = Connection;
                            Command.Transaction = Transaction;
                            Command.CommandType = CommandType.StoredProcedure;
                            Command.CommandText = Input.Name;
                            if (Input.Parameters != null)
                            {
                                foreach (Parameter Parameter in Input.Parameters)
                                {
                                    Command.Parameters.AddWithValue(Parameter.Name, Parameter.Value);
                                }
                            }
                            if (Input.Xml != null)
                            {
                                Command.Parameters.AddWithValue("Xml", JsonConvert.DeserializeXmlNode(JsonConvert.SerializeObject(Input.Xml), null, true).InnerXml);
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
                    catch (Exception ex)
                    {
                        Transaction.Rollback();
                        Context.Response.Clear();
                        Context.Response.ContentType = "text/plain";
                        Context.Response.Write(ex.Message);
                        Context.Response.End();
                    }
                }
                Connection.Close();
            }
        }

        public bool IsReusable { get { return false; } }

    }

}