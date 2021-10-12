package pl.recompiled.gketerraformdemo;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

import static org.springframework.http.HttpStatus.CREATED;

@RestController
@RequestMapping("books")
@RequiredArgsConstructor
public class BookController {

    private final BookRepository repository;

    @GetMapping
    public List<Book> getBooks() {
        return repository.findAll();
    }

    @PostMapping
    public ResponseEntity<Book> addNewBook(@RequestBody AddNewBookRequest request) {
        return ResponseEntity.status(CREATED).body(
                repository.save(Book.of(request.getTitle()))
        );
    }
}
