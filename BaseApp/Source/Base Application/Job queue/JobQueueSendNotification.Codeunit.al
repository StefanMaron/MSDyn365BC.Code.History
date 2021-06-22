codeunit 454 "Job Queue - Send Notification"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        RecordLink: Record "Record Link";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRun(Rec, RecordLink, IsHandled);
        if IsHandled then
            exit;

        RecordLink."Link ID" := 0;
        RecordLink."Record ID" := RecordId;
        if Status = Status::Error then
            RecordLink.Description := CopyStr("Error Message", 1, MaxStrLen(RecordLink.Description))
        else
            RecordLink.Description := Description;
        SetURL(Rec, RecordLink);
        RecordLink.Type := RecordLink.Type::Note;
        RecordLink.Created := CurrentDateTime;
        RecordLink."User ID" := UserId;
        RecordLink.Company := CompanyName;
        RecordLink.Notify := true;
        RecordLink."To User ID" := "User ID";
        SetText(Rec, RecordLink);
        RecordLink.Insert();

        OnAfterRun(Rec, RecordLink);
    end;

    var
        ErrorWhenProcessingTxt: Label 'Error when processing ''%1''.', Comment = '%1 = Job queue entry description';
        ErrorMessageLabelTxt: Label 'Error message:';
        JobQueueFinishedTxt: Label '''%1'' finished successfully.', Comment = '%1 = job description, e.g. ''Post Sales Order 1234''';

    procedure SetJobQueueEntryStatusToOnHold(ModifyOnlyWhenReadOnlyNotification: Notification)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not ModifyOnlyWhenReadOnlyNotification.HasData(JobQueueEntry.FieldName(ID)) then
            exit;

        if JobQueueEntry.Get(ModifyOnlyWhenReadOnlyNotification.GetData(JobQueueEntry.FieldName(ID))) then
            JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
    end;

    local procedure SetURL(var JobQueueEntry: Record "Job Queue Entry"; var RecordLink: Record "Record Link")
    var
        Link: Text;
    begin
        with JobQueueEntry do begin
            // Generates a URL such as dynamicsnav://host:port/instance/company/runpage?page=672&$filter=
            // The intent is to open up the Job Queue Entries page and show the list of "my errors".
            // TODO: Leverage parameters ",JobQueueEntry,TRUE)" to take into account the filters, which will add the
            // following to the Url: &$filter=JobQueueEntry.Status IS 2 AND JobQueueEntry."User ID" IS <UserID>.
            // This will also require setting the filters on the record, such as:
            // SETFILTER(Status,'=2');
            // SETFILTER("User ID",'=%1',"User ID");
            Link := GetUrl(DefaultClientType, CompanyName, OBJECTTYPE::Page, PAGE::"Job Queue Entries") +
              StrSubstNo('&$filter=''%1''.''%2''%20IS%20''2''%20AND%20''%1''.''%3''%20IS%20''%4''&mode=View',
                HtmlEncode(TableName), HtmlEncode(FieldName(Status)), HtmlEncode(FieldName("User ID")), HtmlEncode("User ID"));

            RecordLink.URL1 := CopyStr(Link, 1, MaxStrLen(RecordLink.URL1));
        end;
    end;

    local procedure SetText(var JobQueueEntry: Record "Job Queue Entry"; var RecordLink: Record "Record Link")
    var
        RecordLinkManagement: Codeunit "Record Link Management";
        s: Text;
        lf: Text;
        c1: Byte;
    begin
        with JobQueueEntry do begin
            c1 := 13;
            lf[1] := c1;

            if Status = Status::Error then
                s := StrSubstNo(ErrorWhenProcessingTxt, Description) + lf + ErrorMessageLabelTxt + ' ' + "Error Message"
            else
                s := StrSubstNo(JobQueueFinishedTxt, Description);

            RecordLinkManagement.WriteNote(RecordLink, s);
        end;
    end;

    local procedure HtmlEncode(InText: Text[1024]): Text[1024]
    var
        SystemWebHttpUtility: DotNet HttpUtility;
    begin
        SystemWebHttpUtility := SystemWebHttpUtility.HttpUtility;
        exit(SystemWebHttpUtility.HtmlEncode(InText));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(JobQueueEntry: Record "Job Queue Entry"; RecordLink: Record "Record Link")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var JobQueueEntry: Record "Job Queue Entry"; var RecordLink: Record "Record Link"; var IsHandled: Boolean)
    begin
    end;
}

