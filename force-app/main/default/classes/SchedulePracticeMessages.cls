global class SchedulePracticeMessages implements Schedulable {
//System.schedule('Practice Messages Report', '0 0 7 1 1/1 ? ', new SchedulePracticeMessages());
    global void execute(SchedulableContext SC) { 
        PracticeMessagesEmail.sendEmail();
    }
}