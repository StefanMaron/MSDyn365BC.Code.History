table 951 "Time Sheet Line"
{
    Caption = 'Time Sheet Line';
    Permissions = TableData Employee = r;

    fields
    {
        field(1; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            TableRelation = "Time Sheet Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Time Sheet Starting Date"; Date)
        {
            Caption = 'Time Sheet Starting Date';
            Editable = false;
        }
        field(5; Type; Option)
        {
            Caption = 'Type';
            OptionCaption = ' ,Resource,Job,Service,Absence,Assembly Order';
            OptionMembers = " ",Resource,Job,Service,Absence,"Assembly Order";

            trigger OnValidate()
            begin
                TestStatus;
                if Type = Type::"Assembly Order" then
                    FieldError(Type);
                if Type <> xRec.Type then begin
                    TimeSheetDetail.SetRange("Time Sheet No.", "Time Sheet No.");
                    TimeSheetDetail.SetRange("Time Sheet Line No.", "Line No.");
                    if not TimeSheetDetail.IsEmpty then
                        TimeSheetDetail.DeleteAll();
                    "Job No." := '';
                    Clear("Job Id");
                    "Job Task No." := '';
                    "Service Order No." := '';
                    "Service Order Line No." := 0;
                    "Cause of Absence Code" := '';
                    Description := '';
                    "Assembly Order No." := '';
                    "Assembly Order Line No." := 0;

                    UpdateApproverID;
                end;
            end;
        }
        field(6; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;

            trigger OnValidate()
            begin
                if "Job No." <> '' then begin
                    TestField(Type, Type::Job);
                    Job.Get("Job No.");
                    if Job.Blocked = Job.Blocked::All then
                        Job.TestBlocked;
                end;
                Validate("Job Task No.", '');
                UpdateApproverID;
                UpdateJobId;
            end;
        }
        field(7; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." WHERE("Job No." = FIELD("Job No."));

            trigger OnValidate()
            begin
                if "Job Task No." <> '' then begin
                    TestField(Type, Type::Job);
                    JobTask.Get("Job No.", "Job Task No.");
                    JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
                    Description := JobTask.Description;
                end;
            end;
        }
        field(9; "Cause of Absence Code"; Code[10])
        {
            Caption = 'Cause of Absence Code';
            TableRelation = "Cause of Absence";

            trigger OnValidate()
            var
                Resource: Record Resource;
                Employee: Record Employee;
                CauseOfAbsence: Record "Cause of Absence";
            begin
                if "Cause of Absence Code" <> '' then begin
                    TestField(Type, Type::Absence);
                    CauseOfAbsence.Get("Cause of Absence Code");
                    Description := CauseOfAbsence.Description;
                    TimeSheetHeader.Get("Time Sheet No.");
                    Resource.Get(TimeSheetHeader."Resource No.");
                    Resource.TestField("Base Unit of Measure");
                    Resource.TestField(Type, Resource.Type::Person);
                    Employee.Reset();
                    Employee.SetRange("Resource No.", TimeSheetHeader."Resource No.");
                    if Employee.IsEmpty then
                        Error(Text001, TimeSheetHeader."Resource No.");
                end;
            end;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';

            trigger OnValidate()
            begin
                TestStatus;
            end;
        }
        field(11; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";

            trigger OnValidate()
            begin
                if ("Work Type Code" <> xRec."Work Type Code") and ("Work Type Code" <> '') then
                    CheckWorkType;
            end;
        }
        field(12; "Approver ID"; Code[50])
        {
            Caption = 'Approver ID';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "User Setup";
        }
        field(13; "Service Order No."; Code[20])
        {
            Caption = 'Service Order No.';
            TableRelation = IF (Posted = CONST(false)) "Service Header"."No." WHERE("Document Type" = CONST(Order));

            trigger OnValidate()
            var
                ServiceHeader: Record "Service Header";
            begin
                if "Service Order No." <> '' then begin
                    TestField(Type, Type::Service);
                    ServiceHeader.Get(ServiceHeader."Document Type"::Order, "Service Order No.");
                    Description := CopyStr(
                        StrSubstNo(Text003, "Service Order No.", ServiceHeader."Customer No."),
                        1,
                        MaxStrLen(Description));
                end else
                    Description := '';
            end;
        }
        field(14; "Service Order Line No."; Integer)
        {
            Caption = 'Service Order Line No.';
        }
        field(15; "Total Quantity"; Decimal)
        {
            CalcFormula = Sum("Time Sheet Detail".Quantity WHERE("Time Sheet No." = FIELD("Time Sheet No."),
                                                                  "Time Sheet Line No." = FIELD("Line No.")));
            Caption = 'Total Quantity';
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; Chargeable; Boolean)
        {
            Caption = 'Chargeable';
            InitValue = true;
        }
        field(18; "Assembly Order No."; Code[20])
        {
            Caption = 'Assembly Order No.';
            Editable = false;
            TableRelation = IF (Posted = CONST(false)) "Assembly Header"."No." WHERE("Document Type" = CONST(Order));
        }
        field(19; "Assembly Order Line No."; Integer)
        {
            Caption = 'Assembly Order Line No.';
            Editable = false;
        }
        field(20; Status; Enum "Time Sheet Status")
        {
            Caption = 'Status';
            Editable = false;
        }
        field(21; "Approved By"; Code[50])
        {
            Caption = 'Approved By';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
            TableRelation = "User Setup";
        }
        field(22; "Approval Date"; Date)
        {
            Caption = 'Approval Date';
            Editable = false;
        }
        field(23; Posted; Boolean)
        {
            Caption = 'Posted';
            Editable = false;
        }
        field(26; Comment; Boolean)
        {
            CalcFormula = Exist("Time Sheet Comment Line" WHERE("No." = FIELD("Time Sheet No."),
                                                                 "Time Sheet Line No." = FIELD("Line No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8002; "Job Id"; Guid)
        {
            Caption = 'Job Id';
            DataClassification = SystemMetadata;
            TableRelation = Job.SystemId;
        }
    }

    keys
    {
        key(Key1; "Time Sheet No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; Type)
        {
        }
        key(Key3; "Time Sheet No.", Status, Posted)
        {
        }
        key(Key4; Type, "Job No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        TimeSheetCommentLine: Record "Time Sheet Comment Line";
        Resource: Record Resource;
    begin
        TestStatus;

        GetTimeSheetResource(Resource);
        CheckResourcePrivacyBlocked(Resource);
        Resource.TestField(Blocked, false);

        TimeSheetDetail.SetRange("Time Sheet No.", "Time Sheet No.");
        TimeSheetDetail.SetRange("Time Sheet Line No.", "Line No.");
        TimeSheetDetail.DeleteAll();

        TimeSheetCommentLine.SetRange("No.", "Time Sheet No.");
        TimeSheetCommentLine.SetRange("Time Sheet Line No.", "Line No.");
        TimeSheetCommentLine.DeleteAll();
    end;

    trigger OnInsert()
    var
        Resource: Record Resource;
    begin
        GetTimeSheetResource(Resource);
        CheckResourcePrivacyBlocked(Resource);
        Resource.TestField(Blocked, false);

        UpdateApproverID;
        "Time Sheet Starting Date" := TimeSheetHeader."Starting Date";
    end;

    trigger OnModify()
    var
        Resource: Record Resource;
    begin
        GetTimeSheetResource(Resource);
        CheckResourcePrivacyBlocked(Resource);
        Resource.TestField(Blocked, false);

        UpdateDetails;
    end;

    var
        ResourcesSetup: Record "Resources Setup";
        Job: Record Job;
        JobTask: Record "Job Task";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetDetail: Record "Time Sheet Detail";
        Text001: Label 'There is no employee linked with resource %1.';
        Text002: Label 'Status must be Open or Rejected in line with Time Sheet No.=''%1'', Line No.=''%2''.';
        Text003: Label 'Service order %1 for customer %2';
        Text005: Label 'Select a type before you enter an activity.';
        PrivacyBlockedErr: Label 'You cannot use resource %1 because they are marked as blocked due to privacy.', Comment = '%1=resource no.';

    procedure TestStatus()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestStatus(IsHandled);
        if IsHandled then
            exit;

        if not (Status in [Status::Open, Status::Rejected]) then
            Error(
              Text002,
              "Time Sheet No.",
              "Line No.");
    end;

    local procedure UpdateDetails()
    var
        TimeSheetDetail: Record "Time Sheet Detail";
    begin
        TimeSheetDetail.SetRange("Time Sheet No.", "Time Sheet No.");
        TimeSheetDetail.SetRange("Time Sheet Line No.", "Line No.");
        if TimeSheetDetail.FindSet(true) then
            repeat
                TimeSheetDetail.CopyFromTimeSheetLine(Rec);
                TimeSheetDetail.Modify();
            until TimeSheetDetail.Next = 0;
    end;

    local procedure GetTimeSheetResource(var Resource: Record Resource)
    begin
        TimeSheetHeader.Get("Time Sheet No.");
        Resource.Get(TimeSheetHeader."Resource No.");
    end;

    local procedure GetJobApproverID() ApproverID: Code[50]
    var
        Resource: Record Resource;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetJobApproverID(ApproverID, IsHandled);
        if IsHandled then
            exit(ApproverID);

        Job.Get("Job No.");
        Job.TestField("Person Responsible");
        Resource.Get(Job."Person Responsible");
        Resource.TestField("Time Sheet Owner User ID");
        exit(Resource."Time Sheet Owner User ID");
    end;

    procedure UpdateApproverID()
    var
        Resource: Record Resource;
    begin
        ResourcesSetup.Get();
        GetTimeSheetResource(Resource);
        if (Type = Type::Job) and ("Job No." <> '') and
           (((Resource.Type = Resource.Type::Person) and
             (ResourcesSetup."Time Sheet by Job Approval" = ResourcesSetup."Time Sheet by Job Approval"::Always)) or
            ((Resource.Type = Resource.Type::Machine) and
             (ResourcesSetup."Time Sheet by Job Approval" in [ResourcesSetup."Time Sheet by Job Approval"::"Machine Only",
                                                              ResourcesSetup."Time Sheet by Job Approval"::Always])))
        then
            "Approver ID" := GetJobApproverID()
        else
            SetApproverIDFromResource(Resource);
    end;

    local procedure SetApproverIDFromResource(Resource: Record Resource)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetApproverIDFromResource(Resource, IsHandled);
        if IsHandled then
            exit;

        Resource.TestField("Time Sheet Approver User ID");
        "Approver ID" := Resource."Time Sheet Approver User ID";
    end;

    local procedure CheckWorkType()
    var
        Resource: Record Resource;
        WorkType: Record "Work Type";
    begin
        if WorkType.Get("Work Type Code") then begin
            GetTimeSheetResource(Resource);
            WorkType.TestField("Unit of Measure Code", Resource."Base Unit of Measure");
        end;
    end;

    procedure ShowLineDetails(ManagerRole: Boolean)
    var
        TimeSheetLineResDetail: Page "Time Sheet Line Res. Detail";
        TimeSheetLineJobDetail: Page "Time Sheet Line Job Detail";
        TimeSheetLineServiceDetail: Page "Time Sheet Line Service Detail";
        TimeSheetLineAssembDetail: Page "Time Sheet Line Assemb. Detail";
        TimeSheetLineAbsenceDetail: Page "Time Sheet Line Absence Detail";
    begin
        case Type of
            Type::Resource:
                begin
                    TimeSheetLineResDetail.SetParameters(Rec, ManagerRole);
                    if TimeSheetLineResDetail.RunModal = ACTION::OK then
                        TimeSheetLineResDetail.GetRecord(Rec);
                end;
            Type::Job:
                begin
                    TimeSheetLineJobDetail.SetParameters(Rec, ManagerRole);
                    if TimeSheetLineJobDetail.RunModal = ACTION::OK then
                        TimeSheetLineJobDetail.GetRecord(Rec);
                end;
            Type::Absence:
                begin
                    TimeSheetLineAbsenceDetail.SetParameters(Rec, ManagerRole);
                    if TimeSheetLineAbsenceDetail.RunModal = ACTION::OK then
                        TimeSheetLineAbsenceDetail.GetRecord(Rec);
                end;
            Type::Service:
                begin
                    TimeSheetLineServiceDetail.SetParameters(Rec, ManagerRole);
                    if TimeSheetLineServiceDetail.RunModal = ACTION::OK then
                        TimeSheetLineServiceDetail.GetRecord(Rec);
                end;
            Type::"Assembly Order":
                begin
                    TimeSheetLineAssembDetail.SetParameters(Rec);
                    if TimeSheetLineAssembDetail.RunModal = ACTION::OK then
                        TimeSheetLineAssembDetail.GetRecord(Rec);
                end;
            else
                Error(Text005);
        end;
        Modify;
    end;

    procedure GetAllowEdit(FldNo: Integer; ManagerRole: Boolean) AllowEdit: Boolean
    begin
        if ManagerRole then
            AllowEdit := (FldNo in [FieldNo("Work Type Code"), FieldNo(Chargeable)]) and (Status = Status::Submitted)
        else
            AllowEdit := Status in [Status::Open, Status::Rejected];

        OnAfterGetAllowEdit(FldNo, ManagerRole, AllowEdit);
    end;

    local procedure CheckResourcePrivacyBlocked(Resource: Record Resource)
    begin
        if Resource."Privacy Blocked" then
            Error(PrivacyBlockedErr, Resource."No.");
    end;

    [Scope('OnPrem')]
    procedure UpdateJobId()
    var
        Job: Record Job;
    begin
        if "Job No." = '' then begin
            Clear("Job Id");
            exit;
        end;

        if not Job.Get("Job No.") then
            exit;

        "Job Id" := Job.SystemId;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeTestStatus(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGetJobApproverID(var ApproverID: Code[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSetApproverIDFromResource(Resource: Record Resource; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGetAllowEdit(FldNo: Integer; ManagerRole: Boolean; var AllowEdit: Boolean)
    begin
    end;
}

