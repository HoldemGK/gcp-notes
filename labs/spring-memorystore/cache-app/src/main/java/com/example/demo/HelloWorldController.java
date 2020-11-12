package com.example.demo;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloWorldController {
@Autowired
private StringRedisTemplate template;

@RequestMapping("/hello/{name}")
@Cacheable("hello")
public String hello(@PathVariable String name) throws InterruptedException {
  Thread.sleep(5000);
  return "Hello " + name;
 }
}
