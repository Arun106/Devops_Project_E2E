package com.example.devops;

import org.junit.Test;

import static org.junit.Assert.assertNotNull;

public class HelloServletTest {
    @Test
    public void servletCanBeCreated() {
        assertNotNull(new HelloServlet());
    }
}
