import java.util.*;

class LinkedHashSetDemo{
	public static void main(String [] args){
		//LinkedHashSet<Integer> set = new LinkedHashSet<Integer>();
		//Set<Integer> set = new LinkedHashSet<Integer>();  //valid
		Set<Integer> set = new LinkedHashSet<Integer>(2);  //valid
				
		set.add(1);
		set.add(2);
		set.add(3);
		set.add(4);
		set.add(5);
		set.add(null);
		set.add(6);
		
		System.out.println("\nTraversing using Iterator..");
		Iterator<Integer> iterator = set.iterator();
		while(iterator.hasNext()){
			System.out.println("Family member - " + iterator.next());
		}
		System.out.println("\nTraversing using advanced for loop..");
		for (Integer member:set){
			System.out.println("Family member - "+member);
		}
		System.out.println("\nTraversing using method reference..");
			set.forEach(System.out::println);
			
		System.out.println("\nRemoving elements using set.remove(5)."+set.remove(5));
		
		System.out.println("\nChecking for element presence using set.contains(5) : "+set.contains(5));
		
		System.out.println("\nChecking emptiness using set.isEmpty() : "+set.isEmpty());
				
		System.out.println("\nChecking size using set.size() : "+set.size());
		
		System.out.println("\nClearing set using set.clear() "); 
		set.clear();
		
		System.out.println("\nChecking emptiness using set.isEmpty() : "+set.isEmpty());
	}
}

/*
D:\Final Interview\Collection framwork\Set>java LinkedHashSetDemo.java

Traversing using Iterator..
Family member - 1
Family member - 2
Family member - 3
Family member - 4
Family member - 5
Family member - null
Family member - 6

Traversing using advanced for loop..
Family member - 1
Family member - 2
Family member - 3
Family member - 4
Family member - 5
Family member - null
Family member - 6

Traversing using method reference..
1
2
3
4
5
null
6

Removing elements using set.remove(5).true

Checking for element presence using set.contains(5) : false

Checking emptiness using set.isEmpty() : false

Checking size using set.size() : 6

Clearing set using set.clear()

Checking emptiness using set.isEmpty() : true

D:\Final Interview\Collection framwork\Set>
*/