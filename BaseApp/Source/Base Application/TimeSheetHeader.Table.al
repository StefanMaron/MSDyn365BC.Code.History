table 950 "Time Sheet Header"
{
    Caption = 'Time Sheet Header';

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(3; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
        }
        field(4; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
        }
        field(5; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;

            trigger OnValidate()
            begin
                ResourcesSetup.Get();
                if "Resource No." <> '' then begin
                    Resource.Get("Resource No.");
                    CheckResourcePrivacyBlocked(Resource);
                    Resource.TestField(Blocked, false);
                    Resource.TestField("Time Sheet Owner User ID");
                    Resource.TestField("Time Sheet Approver User ID");
                    "Owner User ID" := Resource."Time Sheet Owner User ID";
                    "Approver User ID" := Resource."Time Sheet Approver User ID";
                end;
            end;
        }
        field(7; "Owner User ID"; Code[50])
        {
            Caption = 'Owner User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
        field(8; "Approver User ID"; Code[50])
        {
            Caption = 'Approver User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = "User Setup";
        }
        field(12; "Open Exists"; Boolean)
        {
            CalcFormula = Exist ("Time Sheet Line" WHERE("Time Sheet No." = FIELD("No."),
                                                         Status = CONST(Open)));
            Caption = 'Open Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(13; "Submitted Exists"; Boolean)
        {
            CalcFormula = Exist ("Time Sheet Line" WHERE("Time Sheet No." = FIELD("No."),
                                                         Status = CONST(Submitted)));
            Caption = 'Submitted Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14; "Rejected Exists"; Boolean)
        {
            CalcFormula = Exist ("Time Sheet Line" WHERE("Time Sheet No." = FIELD("No."),
                                                         Status = CONST(Rejected)));
            Caption = 'Rejected Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Approved Exists"; Boolean)
        {
            CalcFormula = Exist ("Time Sheet Line" WHERE("Time Sheet No." = FIELD("No."),
                                                         Status = CONST(Approved)));
            Caption = 'Approved Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Posted Exists"; Boolean)
        {
            CalcFormula = Exist ("Time Sheet Posting Entry" WHERE("Time Sheet No." = FIELD("No.")));
            Caption = 'Posted Exists';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; Quantity; Decimal)
        {
            CalcFormula = Sum ("Time Sheet Detail".Quantity WHERE("Time Sheet No." = FIELD("No."),
                                                                  Status = FIELD("Status Filter"),
                                                                  "Job No." = FIELD("Job No. Filter"),
                                                                  "Job Task No." = FIELD("Job Task No. Filter"),
                                                                  Date = FIELD("Date Filter"),
                                                                  Posted = FIELD("Posted Filter"),
                                                                  Type = FIELD("Type Filter")));
            Caption = 'Quantity';
            FieldClass = FlowField;
        }
        field(21; "Posted Quantity"; Decimal)
        {
            CalcFormula = Sum ("Time Sheet Posting Entry".Quantity WHERE("Time Sheet No." = FIELD("No.")));
            Caption = 'Posted Quantity';
            FieldClass = FlowField;
        }
        field(26; Comment; Boolean)
        {
            CalcFormula = Exist ("Time Sheet Comment Line" WHERE("No." = FIELD("No."),
                                                                 "Time Sheet Line No." = CONST(0)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Status Filter"; Enum "Time Sheet Status")
        {
            Caption = 'Status Filter';
            FieldClass = FlowFilter;
        }
        field(31; "Job No. Filter"; Code[20])
        {
            Caption = 'Job No. Filter';
            FieldClass = FlowFilter;
        }
        field(32; "Job Task No. Filter"; Code[20])
        {
            Caption = 'Job Task No. Filter';
            FieldClass = FlowFilter;
        }
        field(33; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(34; "Posted Filter"; Boolean)
        {
            Caption = 'Posted Filter';
            FieldClass = FlowFilter;
        }
        field(35; "Type Filter"; Option)
        {
            Caption = 'Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = ' ,Resource,Job,Service,Absence,Assembly Order';
            OptionMembers = " ",Resource,Job,Service,Absence,"Assembly Order";
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Resource No.", "Starting Date")
        {
        }
        key(Key3; "Owner User ID")
        {
        }
        key(Key4; "Approver User ID")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Starting Date", "Ending Date", "Resource No.")
        {
        }
    }

    trigger OnDelete()
    var
        TimeSheetCommentLine: Record "Time Sheet Comment Line";
    begin
        if "Resource No." <> '' then begin
            Resource.Get("Resource No.");
            CheckResourcePrivacyBlocked(Resource);
            Resource.TestField(Blocked, false);
        end;

        TimeSheetLine.SetRange("Time Sheet No.", "No.");
        TimeSheetLine.DeleteAll(true);

        TimeSheetCommentLine.SetRange("No.", "No.");
        TimeSheetCommentLine.SetRange("Time Sheet Line No.", 0);
        TimeSheetCommentLine.DeleteAll();

        RemoveFromMyTimeSheets;
    end;

    trigger OnInsert()
    begin
        if "Resource No." <> '' then begin
            Resource.Get("Resource No.");
            CheckResourcePrivacyBlocked(Resource);
            Resource.TestField(Blocked, false);
            if Resource."Time Sheet Owner User ID" <> '' then
                AddToMyTimeSheets(Resource."Time Sheet Owner User ID");
        end;
    end;

    trigger OnModify()
    begin
        if "Resource No." <> '' then begin
            Resource.Get("Resource No.");
            CheckResourcePrivacyBlocked(Resource);
            Resource.TestField(Blocked, false);
        end;
    end;

    trigger OnRename()
    begin
        if "Resource No." <> '' then begin
            Resource.Get("Resource No.");
            CheckResourcePrivacyBlocked(Resource);
            Resource.TestField(Blocked, false);
        end;
    end;

    var
        Resource: Record Resource;
        ResourcesSetup: Record "Resources Setup";
        TimeSheetLine: Record "Time Sheet Line";
        Text001: Label '%1 does not contain lines.';
        TimeSheetMgt: Codeunit "Time Sheet Management";
        Text002: Label 'No time sheets are available. The time sheet administrator must create time sheets before you can access them in this window.';
        PrivacyBlockedErr: Label 'You cannot use resource %1 because they are marked as blocked due to privacy.', Comment = '%1=resource no.';

    procedure CalcQtyWithStatus(Status: Enum "Time Sheet Status"): Decimal
    begin
        SetRange("Status Filter", Status);
        CalcFields(Quantity);
        exit(Quantity);
    end;

    procedure Check()
    begin
        TimeSheetLine.SetRange("Time Sheet No.", "No.");
        if TimeSheetLine.FindSet then begin
            repeat
                TimeSheetLine.TestField(Status, TimeSheetLine.Status::Approved);
                TimeSheetLine.TestField(Posted, true);
            until TimeSheetLine.Next = 0;
        end else
            Error(Text001, "No.");
    end;

    procedure GetLastLineNo(): Integer
    begin
        TimeSheetLine.Reset();
        TimeSheetLine.SetRange("Time Sheet No.", "No.");
        if TimeSheetLine.FindLast then;
        exit(TimeSheetLine."Line No.");
    end;

    procedure FindLastTimeSheetNo(FilterFieldNo: Integer): Code[20]
    begin
        Reset;
        SetCurrentKey("Resource No.", "Starting Date");

        TimeSheetMgt.FilterTimeSheets(Rec, FilterFieldNo);
        SetFilter("Starting Date", '%1..', WorkDate);
        if not FindFirst then begin
            SetRange("Starting Date");
            SetRange("Ending Date");
            if not FindLast then
                Error(Text002);
        end;
        exit("No.");
    end;

    local procedure AddToMyTimeSheets(UserID: Code[50])
    var
        MyTimeSheets: Record "My Time Sheets";
    begin
        MyTimeSheets.Init();
        MyTimeSheets."User ID" := UserID;
        MyTimeSheets."Time Sheet No." := "No.";
        MyTimeSheets."Start Date" := "Starting Date";
        MyTimeSheets."End Date" := "Ending Date";
        MyTimeSheets.Comment := Comment;
        MyTimeSheets.Insert();
    end;

    local procedure RemoveFromMyTimeSheets()
    var
        MyTimeSheets: Record "My Time Sheets";
    begin
        MyTimeSheets.SetRange("Time Sheet No.", "No.");
        if MyTimeSheets.FindFirst then
            MyTimeSheets.DeleteAll();
    end;

    local procedure CheckResourcePrivacyBlocked(Resource: Record Resource)
    begin
        if Resource."Privacy Blocked" then
            Error(PrivacyBlockedErr, Resource."No.");
    end;
}

