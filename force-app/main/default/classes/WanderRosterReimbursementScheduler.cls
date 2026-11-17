
public class WanderRosterReimbursementScheduler implements Schedulable {

    public void execute(SchedulableContext context) {
        Database.executeBatch(
            new WanderRosterReimbursementBatch(),
            100
        );
    }
}
