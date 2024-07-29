import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
class ExecuterTest implements Runnable{
	String taskName;
	ExecuterTest(String a){
		taskName=a;
	}
	@Override
	public void run(){
		System.out.println("Thread name - "+Thread.currentThread().getName()+" | Executitng task - " + taskName);
		try{
			Thread.sleep(100);
		}
		catch(Exception e){
			
		}
	}
	
	public static void main(String [] args){
		ExecutorService ES = Executors.newFixedThreadPool(4);
		
		for (int i=0; i<10;i++){
			String taskName = "Task-"+i;
			ExecuterTest task = new ExecuterTest(taskName);
			
			ES.submit(task);
		}
		ES.shutdown();
	}
}


/* you can use try with resource as well like below-
	public static void main(String [] args){
		try(ExecutorService ES = Executors.newFixedThreadPool(4)){
		
		for (int i=0; i<10;i++){
			String taskName = "Task-"+i;
			ExecuterTest task = new ExecuterTest(taskName);
			
			ES.submit(task);
		}
		}
		catch(Exception e){
			
		}
		//ES.shutdown();
	}
*/

/*

D:\Final Interview\Core java\Mulitthreading\Coding>java ExecuterTest.java
Thread name - pool-1-thread-4 | Executitng task - Task-3
Thread name - pool-1-thread-3 | Executitng task - Task-2
Thread name - pool-1-thread-2 | Executitng task - Task-1
Thread name - pool-1-thread-1 | Executitng task - Task-0
Thread name - pool-1-thread-4 | Executitng task - Task-4
Thread name - pool-1-thread-2 | Executitng task - Task-5
Thread name - pool-1-thread-1 | Executitng task - Task-6
Thread name - pool-1-thread-3 | Executitng task - Task-7
Thread name - pool-1-thread-1 | Executitng task - Task-8
Thread name - pool-1-thread-2 | Executitng task - Task-9

D:\Final Interview\Core java\Mulitthreading\Coding>
*/