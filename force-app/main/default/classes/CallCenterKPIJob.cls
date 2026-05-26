/*
 * Calculate KPIs based on data in Call_Center_Summary__c records, which are created
 * by BatchCallCenterSummary
*/


public class CallCenterKPIJob {

    public static void run(Date startDate, Date endDate) {
        if (startDate == null || endDate == null) {
            throw new IllegalArgumentException('Start and end dates are required.');
        }
        if (startDate > endDate) {
            throw new IllegalArgumentException('Start date must be on or before end date.');
        }

        System.debug('Running KPI job for date range: ' + startDate + ' to ' + endDate);
        calculateAndInsertKPIs(startDate, endDate);
    }

    private static void calculateAndInsertKPIs(Date startDate, Date endDate) {

        List<Call_Center_Summary__c> summaries = [
            SELECT Id, KPI_Date__c, Company__c,
                TotalAbandoned__c, TotalAnswered__c, TotalAnsweredInSVL__c, TotalAnswerTime__c,
                TotalAppointments__c, TotalClosed__c, TotalDispositionCount__c, TotalInbound__c,
                TotalOffered__c, TotalQuestion1__c, TotalResolved__c, TotalScheduledCount__c,
                TotalSurveys__c, TotalTransfers__c
            FROM Call_Center_Summary__c
            WHERE KPI_Date__c >= :startDate AND KPI_Date__c <= :endDate
        ];

        // Initialize totals
        Decimal totalAnswered = 0;
        Decimal totalAnsweredInSVL = 0;
        Decimal totalAppointments = 0;
        Decimal totalOffered = 0;
        Decimal totalAbandoned = 0;
        Decimal totalAnswerTime = 0;
        Decimal totalInbound = 0;
        Decimal totalTransfers = 0;
        Decimal totalClosed = 0;
        Decimal totalResolved = 0;
        Decimal totalDispositionCount = 0;
        Decimal scheduledCount = 0;
        Decimal totalQuestion1 = 0;
        Decimal totalSurveys = 0;

        // Sum values
        for (Call_Center_Summary__c cs : summaries) {
            totalAnswered += cs.TotalAnswered__c;
            totalAnsweredInSVL += cs.TotalAnsweredInSVL__c;
            totalAppointments += cs.TotalAppointments__c;
            totalOffered += cs.TotalOffered__c;
            totalAbandoned += cs.TotalAbandoned__c;
            totalAnswerTime += cs.TotalAnswerTime__c;
            totalInbound += cs.TotalInbound__c;
            totalTransfers += cs.TotalTransfers__c;
            totalClosed += cs.TotalClosed__c;
            totalResolved += cs.TotalResolved__c;
            totalDispositionCount += cs.TotalDispositionCount__c;
            scheduledCount += cs.TotalScheduledCount__c;
            totalQuestion1 += cs.TotalQuestion1__c;
            totalSurveys += cs.TotalSurveys__c;
        }

        // Calculations
        Decimal serviceLevel = (totalOffered > 0) ? (totalAnsweredInSVL / totalOffered) : 0;
        Decimal asa = (totalAnswered > 0) ? (totalAnswerTime / totalAnswered) : 0;
        Decimal abandonRate = (totalOffered > 0) ? (totalAbandoned / totalOffered) : 0;
        Decimal transferRate = ((totalInbound + totalTransfers) > 0) ? (totalTransfers / (totalInbound + totalTransfers)) : 0;
        Decimal fcr = (totalClosed > 0) ? (totalResolved / totalClosed) : 0;
        Decimal scheduleRate = (totalDispositionCount > 0) ? (scheduledCount / totalDispositionCount) : 0;
        Decimal avgQuestion1 = (totalSurveys > 0) ? (totalQuestion1 / totalSurveys) : 0;

        // Log values
        System.debug('Total Answered: ' + totalAnswered);
        System.debug('ASA: ' + asa);
        System.debug('Appointments: ' + totalAppointments);
        System.debug('Abandon Rate: ' + abandonRate);
        System.debug('FCR: ' + fcr);
        System.debug('Schedule Rate: ' + scheduleRate);
        System.debug('CSAT: ' + avgQuestion1);
        System.debug('Transfer Rate: ' + transferRate);
        System.debug('Service Level: ' + serviceLevel);

        // Insert KPI record
        Call_Center_KPI__c kpi = new Call_Center_KPI__c(
            Start_Date__c = startDate,
            End_Date__c = endDate,
            Calls_Answered__c = totalAnswered,
            ASA__c = asa.setScale(2, RoundingMode.HALF_UP),
            Appt_Scheduled__c = totalAppointments,
            Abandoned_Rate__c = abandonRate.setScale(4, RoundingMode.HALF_UP),
            FCR__c = fcr.setScale(4, RoundingMode.HALF_UP),
            Schedule_Rate__c = scheduleRate.setScale(4, RoundingMode.HALF_UP),
            CSAT__c = avgQuestion1.setScale(2, RoundingMode.HALF_UP),
            Transfer_Rate__c = transferRate.setScale(4, RoundingMode.HALF_UP),
            SL__c = serviceLevel.setScale(4, RoundingMode.HALF_UP)
        );

        insert kpi;
    }
}