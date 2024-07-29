import java.util.*;
import java.util.stream.*;

public class CollectorsExample {
    public static void main(String[] args) {
        List<String> names = Arrays.asList("Alice", "Bob", "Charlie", "David", "Edward","Alice", "Bob", "Charlie");

        // Collect to List
        List<String> namesList = names.stream().collect(Collectors.toList());
        System.out.println("List: " + namesList);
		
		//List<String> namesList = names.stream().count().collect(Collectors.toList());
		
		// Collect to distinct List
        List<String> namesList = names.stream().distinct().collect(Collectors.toList());
        System.out.println("List: " + namesList);

        // Collect to Set
        Set<String> namesSet = names.stream().collect(Collectors.toSet());
        System.out.println("Set: " + namesSet);

        // Joining
        String joinedNames = names.stream().collect(Collectors.joining(", "));
        System.out.println("Joined: " + joinedNames);

        // Counting
        long count = names.stream().collect(Collectors.counting());
        System.out.println("Count: " + count);

    }
}


/*
D:\Final Interview\Collection framwork\Stream API>java CollectorsExample.java
List: [Alice, Bob, Charlie, David, Edward]
Set: [Bob, Alice, Charlie, David, Edward]
Joined: Alice, Bob, Charlie, David, Edward, Alice, Bob, Charlie
Count: 8

D:\Final Interview\Collection framwork\Stream API>java CollectorsExample.java
CollectorsExample.java:9: error: long cannot be dereferenced
        List<String> namesList = names.stream().count().collect(Collectors.toList());
                                                       ^
1 error
error: compilation failed

D:\Final Interview\Collection framwork\Stream API>
*/