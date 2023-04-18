page 971 "Activity Details FactBox"
{
    Caption = 'Activity Details';
    PageType = CardPart;
    SourceTable = "Time Sheet Line";

    layout
    {
        area(content)
        {
            field(Comment; Comment)
            {
                ApplicationArea = Comments;
                Caption = 'Line Comment';
                DrillDown = false;
                ToolTip = 'Specifies that a comment about this document has been entered.';
            }
            field("Total Quantity"; Rec."Total Quantity")
            {
                ApplicationArea = Jobs;
                Caption = 'Line Total';
                DrillDown = false;
                ToolTip = 'Specifies the total number of hours that have been entered on a time sheet.';
            }
            field(ActivitiID; ActivitiID)
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + ActivityCaption;

                trigger OnLookup(var Text: Text): Boolean
                begin
                    LookupActivity();
                end;
            }
            field(ActivitySubID; ActivitySubID)
            {
                ApplicationArea = Jobs;
                CaptionClass = '3,' + ActivitySubCaption;

                trigger OnLookup(var Text: Text): Boolean
                begin
                    LookupSubActivity();
                end;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        TimeSheetMgt.GetActivityInfo(Rec, ActivityCaption, ActivitiID, ActivitySubCaption, ActivitySubID);
    end;

    var
        TimeSheetMgt: Codeunit "Time Sheet Management";
        ActivityCaption: Text[30];
        ActivitySubCaption: Text;
        ActivitiID: Code[20];
        ActivitySubID: Code[20];

    procedure SetEmptyLine()
    begin
        ActivityCaption := '';
        ActivitiID := '';
        ActivitySubCaption := '';
        ActivitiID := '';
    end;

    local procedure LookupActivity()
    var
        Job: Record Job;
        CauseOfAbsence: Record "Cause of Absence";
        ServiceHeader: Record "Service Header";
        AssemblyHeader: Record "Assembly Header";
        JobList: Page "Job List";
        CausesOfAbsence: Page "Causes of Absence";
        ServiceOrders: Page "Service Orders";
        AssemblyOrders: Page "Assembly Orders";
    begin
        case Type of
            Type::Job:
                begin
                    Clear(JobList);
                    if "Job No." <> '' then begin
                        Job.Get("Job No.");
                        JobList.SetRecord(Job);
                    end;
                    JobList.RunModal();
                end;
            Type::Absence:
                begin
                    Clear(CausesOfAbsence);
                    if "Cause of Absence Code" <> '' then begin
                        CauseOfAbsence.Get("Cause of Absence Code");
                        CausesOfAbsence.SetRecord(CauseOfAbsence);
                    end;
                    CausesOfAbsence.RunModal();
                end;
            Type::Service:
                begin
                    Clear(ServiceOrders);
                    if "Service Order No." <> '' then
                        if ServiceHeader.Get(ServiceHeader."Document Type"::Order, "Service Order No.") then
                            ServiceOrders.SetRecord(ServiceHeader);
                    ServiceOrders.RunModal();
                end;
            Type::"Assembly Order":
                begin
                    Clear(AssemblyOrders);
                    if "Assembly Order No." <> '' then
                        if AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, "Assembly Order No.") then
                            AssemblyOrders.SetRecord(AssemblyHeader);
                    AssemblyOrders.RunModal();
                end;
        end;
    end;

    local procedure LookupSubActivity()
    var
        JobTask: Record "Job Task";
        JobTaskList: Page "Job Task List";
        IsHandled: Boolean;
    begin
        OnBeforeLookupSubActivity(Rec, IsHandled);
        if IsHandled then
            exit;

        if Type = Type::Job then begin
            Clear(JobTaskList);
            if "Job Task No." <> '' then begin
                JobTask.Get("Job No.", "Job Task No.");
                JobTaskList.SetRecord(JobTask);
            end;
            JobTaskList.RunModal();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupSubActivity(TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean)
    begin
    end;
}

