package com.example.todos.store;

import com.example.todos.model.Todo;
import org.springframework.stereotype.Component;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

@Component
public class TodoStore {
  private final Map<Long, Todo> data = new ConcurrentHashMap<>();
  private final AtomicLong ids = new AtomicLong();

  public List<Todo> all() {
    return new ArrayList<>(data.values());
  }

  public Optional<Todo> get(Long id) {
    return Optional.ofNullable(data.get(id));
  }

  public Todo create(String title) {
    long id = ids.incrementAndGet();
    Todo t = new Todo(id, title, false);
    data.put(id, t);
    return t;
  }

  public Optional<Todo> update(Long id, String title, boolean done) {
    if (!data.containsKey(id))
      return Optional.empty();
    Todo t = new Todo(id, title, done);
    data.put(id, t);
    return Optional.of(t);
  }

  public void delete(Long id) {
    data.remove(id);
  }
}
