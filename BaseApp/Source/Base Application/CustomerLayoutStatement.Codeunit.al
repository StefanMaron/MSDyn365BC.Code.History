codeunit 8810 "Customer Layout - Statement"
{

    trigger OnRun()
    begin
    end;

    var
        StatementFileNameTxt: Label 'Statement', Comment='Shortened form of ''Customer Statement''';
        StatementReportNotFoundErr: Label 'No customer statement report has been set up.';
        RunCustomerStatementsTxt: Label 'Run Customer Statements from Job Queue.';
        DuplicateJobQueueRecordErr: Label 'Customer statements are already scheduled to run in the job queue.';
        ConfirmRunRepInBackgroundQst: Label 'Do you want to set the job queue entry up to run immediately?';

    [Scope('OnPrem')]
    procedure RunReport()
    var
        Customer: Record Customer;
        ReportSelections: Record "Report Selections";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::Customer);
        CustomLayoutReporting.SetOutputFileBaseName(StatementFileNameTxt);
        CustomLayoutReporting.ProcessReportForData(
          ReportSelections.Usage::"C.Statement",RecRef,Customer.FieldName("No."),DATABASE::Customer,Customer.FieldName("No."),true);
    end;

    [Scope('OnPrem')]
    procedure RunReportWithParameters(Parameters: Text)
    var
        Customer: Record Customer;
        ReportSelections: Record "Report Selections";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::Customer);
        CustomLayoutReporting.SetOutputFileBaseName(StatementFileNameTxt);
        CustomLayoutReporting.SetPredefinedRequestParameters(Parameters);
        CustomLayoutReporting.ProcessReportForData(
          ReportSelections.Usage::"C.Statement",RecRef,Customer.FieldName("No."),DATABASE::Customer,Customer.FieldName("No."),true);
    end;

    [Scope('OnPrem')]
    procedure RunReportWithoutRequestPage()
    var
        Customer: Record Customer;
        ReportSelections: Record "Report Selections";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        RecRef: RecordRef;
    begin
        RecRef.Open(DATABASE::Customer);
        CustomLayoutReporting.SetOutputFileBaseName(StatementFileNameTxt);
        CustomLayoutReporting.SetIgnoreRequestParameters(true);
        CustomLayoutReporting.ProcessReportForData(
          ReportSelections.Usage::"C.Statement",RecRef,Customer.FieldName("No."),DATABASE::Customer,Customer.FieldName("No."),true);
    end;

    [Scope('OnPrem')]
    procedure EnqueueReport()
    var
        JobQueueEntry: Record "Job Queue Entry";
        LocalReportSelections: Record "Report Selections";
        CustomLayoutReporting: Codeunit "Custom Layout Reporting";
        RequestParameters: Text;
        RunImmediately: Boolean;
        LocalRepId: Integer;
    begin
        LocalReportSelections.SetRange(Usage,LocalReportSelections.Usage::"C.Statement");
        if not LocalReportSelections.FindFirst then
          Error(StatementReportNotFoundErr);

        LocalRepId := LocalReportSelections."Report ID";
        RequestParameters := CustomLayoutReporting.RunRequestPage(LocalRepId);
        if RequestParameters = '' then
          exit;

        RunImmediately := Confirm(ConfirmRunRepInBackgroundQst);
        CheckReportRunningInBackground;
        with JobQueueEntry do begin
          Init;
          Scheduled := false;
          Status := Status::"On Hold";
          Description := RunCustomerStatementsTxt;
          "Object ID to Run" := CODEUNIT::"Customer Statement via Queue";
          "Object Type to Run" := "Object Type to Run"::Codeunit;
          Insert(true); // it is required due to MODIFY called inside SetReportParameters
          SetXmlContent(RequestParameters);
          if RunImmediately then
            SetStatus(Status::Ready);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckReportRunningInBackground()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        SetJobQueueEntryFilter(JobQueueEntry);
        if JobQueueEntry.FindFirst then
          if JobQueueEntry.DoesExistLocked then
            Error(DuplicateJobQueueRecordErr);
    end;

    local procedure SetJobQueueEntryFilter(var JobQueueEntry: Record "Job Queue Entry")
    begin
        JobQueueEntry.SetRange("Object ID to Run",CODEUNIT::"Customer Statement via Queue");
        JobQueueEntry.SetRange("Object Type to Run",JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("User ID",UserId);
    end;
}

