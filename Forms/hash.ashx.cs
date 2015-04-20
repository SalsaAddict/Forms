﻿using System.Web;

namespace mg
{

    public class hash : IHttpHandler
    {

        public void ProcessRequest(HttpContext Context)
        {
            string Password = Context.Request.QueryString[0];
            string Hash = PasswordHash.CreateHash(Password);
            bool Compare = PasswordHash.ValidatePassword(Password, Hash);
            Context.Response.ContentType = "text/plain";
            Context.Response.Write(string.Format("Original: {0}\r\nHash: {1}\r\nCompare: {2}", Password, Hash, Compare));
        }

        public bool IsReusable { get { return false; } }

    }

}