package com.example.devops;

import org.junit.Test;
import javax.servlet.http.HttpServletResponse;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.lang.reflect.Proxy;

import static org.junit.Assert.assertTrue;

public class HelloServletTest {
    @Test
    public void healthEndpointReturnsExpectedResponse() throws Exception {
        StringWriter body = new StringWriter();
        PrintWriter writer = new PrintWriter(body);
        HttpServletResponse response = (HttpServletResponse) Proxy.newProxyInstance(
                HttpServletResponse.class.getClassLoader(),
                new Class<?>[] { HttpServletResponse.class },
                (proxy, method, args) -> {
                    if (method.getName().equals("getWriter")) return writer;
                    return null;
                });

        new HelloServlet().doGet(null, response);
        writer.flush();
        assertTrue(body.toString().contains("SUCCESS: DevOps E2E app is running"));
    }
}
