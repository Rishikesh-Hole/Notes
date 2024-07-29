// overriding default method in sub interface
class TestAB implements B{
	public static void main(String [] args){
		System.out.println(" inside main!!");
		TestAB T = new TestAB();
		T.m1();
	}
	
}

interface A{
	//private default void m1(){ //error: illegal combination of modifiers: private and default
	// protected default void m1(){ // error: modifier protected not allowed here
	default void m1(){
		System.out.println("inside A!!");
		
	}
}

interface B extends A{
	default void m1(){
		System.out.println(" Inside B - default void m1()!!");
	}
	private static void m2(){
		System.out.println(" B - static void m2()!!");
	}
}


/*
D:\Final Interview\Core java\interface\coding>java InterfaceTest6.java
InterfaceTest6.java:12: error: illegal combination of modifiers: private and default
        private default void m1(){
                             ^
1 error
error: compilation failed

D:\Final Interview\Core java\interface\coding>java InterfaceTest6.java
InterfaceTest6.java:13: error: modifier protected not allowed here
        protected default void m1(){
                               ^
1 error
error: compilation failed

D:\Final Interview\Core java\interface\coding>java InterfaceTest6.java
inside main!!
inside B!!

D:\Final Interview\Core java\interface\coding>java InterfaceTest6.java
inside main!!
inside B!!

D:\Final Interview\Core java\interface\coding>java InterfaceTest6.java
inside main!!
 Inside B - default void m1()!!

D:\Final Interview\Core java\interface\coding>java InterfaceTest6.java
 inside main!!
 Inside B - default void m1()!!

D:\Final Interview\Core java\interface\coding>
*/