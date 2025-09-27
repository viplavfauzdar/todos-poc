package com.example.todos.api;
import com.example.todos.model.Todo;
import com.example.todos.store.TodoStore;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.net.URI; import java.util.List;
@RestController @RequestMapping("/api/todos")
public class TodoController {
  private final TodoStore store; public TodoController(TodoStore store){this.store=store;}
  @GetMapping public List<Todo> all(){return store.all();}
  @GetMapping("/{id}") public ResponseEntity<Todo> one(@PathVariable Long id){return store.get(id).map(ResponseEntity::ok).orElse(ResponseEntity.notFound().build());}
  @PostMapping public ResponseEntity<Todo> create(@RequestBody TodoDTO dto){Todo saved=store.create(dto.title()); return ResponseEntity.created(URI.create("/api/todos/"+saved.id())).body(saved);}
  @PutMapping("/{id}") public ResponseEntity<Todo> update(@PathVariable Long id,@RequestBody TodoDTO dto){return store.update(id,dto.title(),dto.done()).map(ResponseEntity::ok).orElse(ResponseEntity.notFound().build());}
  @DeleteMapping("/{id}") public ResponseEntity<Void> delete(@PathVariable Long id){store.delete(id); return ResponseEntity.noContent().build();}
}
