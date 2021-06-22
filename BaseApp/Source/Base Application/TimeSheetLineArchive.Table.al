table 955 "Time Sheet Line Archive"
{
    Caption = 'Time Sheet Line Archive';

    fields
    {
        field(1; "Time Sheet No."; Code[20])
        {
            Caption = 'Time Sheet No.';
            TableRelation = "Time Sheet Header Archive";
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
        }
        field(6; "Job No."; Code[20])
        {
            Caption = 'Job No.';
            TableRelation = Job;
        }
        field(7; "Job Task No."; Code[20])
        {
            Caption = 'Job Task No.';
            TableRelation = "Job Task"."Job Task No." WHERE("Job No." = FIELD("Job No."));
        }
        field(9; "Cause of Absence Code"; Code[10])
        {
            Caption = 'Cause of Absence Code';
            TableRelation = "Cause of Absence";
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(11; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";
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
        }
        field(14; "Service Order Line No."; Integer)
        {
            Caption = 'Service Order Line No.';
        }
        field(15; "Total Quantity"; Decimal)
        {
            CalcFormula = Sum ("Time Sheet Detail Archive".Quantity WHERE("Time Sheet No." = FIELD("Time Sheet No."),
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
            TableRelation = IF (Posted = CONST(false)) "Assembly Header"."No." WHERE("Document Type" = CONST(Order));
        }
        field(19; "Assembly Order Line No."; Integer)
        {
            Caption = 'Assembly Order Line No.';
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
            CalcFormula = Exist ("Time Sheet Comment Line" WHERE("No." = FIELD("Time Sheet No."),
                                                                 "Time Sheet Line No." = FIELD("Line No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Time Sheet No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        TimeSheetDetailArchive: Record "Time Sheet Detail Archive";
        TimeSheetCmtLineArchive: Record "Time Sheet Cmt. Line Archive";
    begin
        TimeSheetDetailArchive.SetRange("Time Sheet No.", "Time Sheet No.");
        TimeSheetDetailArchive.SetRange("Time Sheet Line No.", "Line No.");
        TimeSheetDetailArchive.DeleteAll();

        TimeSheetCmtLineArchive.SetRange("No.", "Time Sheet No.");
        TimeSheetCmtLineArchive.SetRange("Time Sheet Line No.", "Line No.");
        TimeSheetCmtLineArchive.DeleteAll();
    end;
}

