using System.Web;

namespace SqlUi
{

    public class hash : IHttpHandler
    {

        public void ProcessRequest(HttpContext Context)
        {
            string Password = Context.Request.QueryString[0];
            string Hash = Security.HashPassword(Password);
            bool Compare = Security.ValidatePassword(Password, Hash);
            Context.Response.ContentType = "text/plain";
            Context.Response.Write(string.Format("Original: {0}\r\nHash: {1}\r\nCompare: {2}", Password, Hash, Compare));
        }

        public bool IsReusable { get { return false; } }

    }

}