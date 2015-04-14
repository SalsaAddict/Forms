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

    public class read : IHttpHandler
    {

        private class Parameter
        {
            [JsonProperty("Name")]
            public string Name { get; set; }

            [JsonProperty("Value")]
            public string Value { get; set; }
        }

        private class Template
        {
            [JsonProperty("Name")]
            public string Name { get; set; }

            [JsonProperty("Parameters")]
            public List<Parameter> Parameters { get; set; }
        }

        public void ProcessRequest(HttpContext Context)
        {
            Template Input;
            using (StreamReader Reader = new StreamReader(Context.Request.InputStream, Encoding.UTF8))
            {
                Input = JsonConvert.DeserializeObject<Template>(Reader.ReadToEnd());
                Reader.Close();
            }
            using (SqlConnection Connection = new SqlConnection(WebConfigurationManager.ConnectionStrings["Database"].ConnectionString))
            {
                Connection.Open();
                using (SqlTransaction Transaction = Connection.BeginTransaction(IsolationLevel.Serializable))
                {
                    try
                    {
                        string SourceType, Source;
                        string Fields = string.Empty, Parameters = string.Empty, CommandText = string.Empty;
                        using (SqlCommand Command = new SqlCommand())
                        {
                            Command.Connection = Connection;
                            Command.Transaction = Transaction;
                            Command.CommandType = CommandType.StoredProcedure;
                            Command.CommandText = "pr_UiRead";
                            Command.Parameters.AddWithValue("Id", Input.Name);
                            using (SqlDataReader Reader = Command.ExecuteReader(CommandBehavior.Default))
                            {
                                Reader.Read();
                                SourceType = Reader.GetString(0);
                                Source = Reader.GetString(1);
                                Reader.NextResult();
                                while (Reader.Read())
                                {
                                    if (!string.IsNullOrWhiteSpace(Fields)) Fields += ", ";
                                    Fields += string.Format("[{0}]", Reader.GetString(0));
                                }
                                Reader.Close();
                            }
                        }
                        using (SqlCommand Command = new SqlCommand())
                        {
                            Command.Connection = Connection;
                            Command.Transaction = Transaction;
                            if (SourceType == "T")
                            {
                                CommandText = string.Format("SELECT {0} FROM [{1}]", Fields, Source);
                                int i = 0;
                                foreach (Parameter Parameter in Input.Parameters)
                                {
                                    Parameters += (string.IsNullOrWhiteSpace(Parameters)) ? "WHERE" : "AND";
                                    Parameters += string.Format(" [{0}] = @p{1}", Parameter.Name, i.ToString());
                                }
                                CommandText += string.Format(" {0}", Parameters);
                                Command.CommandType = CommandType.Text;
                            }
                            Command.CommandText = CommandText;
                            int j = 0;
                            foreach (Parameter Parameter in Input.Parameters)
                            {
                                Command.Parameters.AddWithValue(string.Format("p{0}", j), Parameter.Value);
                            }
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
            }


        }

        public bool IsReusable { get { return false; } }

    }

}