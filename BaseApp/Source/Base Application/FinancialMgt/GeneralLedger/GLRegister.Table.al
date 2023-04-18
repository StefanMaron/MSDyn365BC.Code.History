table 45 "G/L Register"
{
    Caption = 'G/L Register';
    LookupPageID = "G/L Registers";
    Permissions = TableData "G/L Register" = rimd;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "From Entry No."; Integer)
        {
            Caption = 'From Entry No.';
            TableRelation = "G/L Entry";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(3; "To Entry No."; Integer)
        {
            Caption = 'To Entry No.';
            TableRelation = "G/L Entry";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
        }
        field(5; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(6; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(7; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(8; "From VAT Entry No."; Integer)
        {
            Caption = 'From VAT Entry No.';
            TableRelation = "VAT Entry";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(9; "To VAT Entry No."; Integer)
        {
            Caption = 'To VAT Entry No.';
            TableRelation = "VAT Entry";
            //This property is currently not supported
            //TestTableRelation = false;
        }
        field(10; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        field(11; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
        }
        field(12; "Journal Templ. Name"; Code[10])
        {
            Caption = 'Journal Template Name';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Creation Date")
        {
        }
        key(Key3; "Source Code", "Journal Batch Name", "Creation Date")
        {
        }
        key(key4; "From Entry No.", "To Entry No.")
        {
            IncludedFields = "Creation Date";
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "From Entry No.", "To Entry No.", "Creation Date", "Source Code")
        {
        }
    }

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("No.")))
    end;

    procedure Initialize(NextRegNo: Integer; FromEntryNo: Integer; FromVATEntryNo: Integer; SourceCode: Code[10]; BatchName: Code[10]; TemplateName: Code[10])
    begin
        Init();
        OnInitializeOnAfterGLRegisterInit(Rec, TemplateName);
        "No." := NextRegNo;
        "Creation Date" := Today;
        "Creation Time" := Time;
        "Source Code" := SourceCode;
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        "From Entry No." := FromEntryNo;
        "From VAT Entry No." := FromVATEntryNo;
        "Journal Batch Name" := BatchName;
        "Journal Templ. Name" := TemplateName;
    end;


    [IntegrationEvent(false, false)]
    local procedure OnInitializeOnAfterGLRegisterInit(var GLRegister: record "G/L Register"; TemplateName: Code[10])
    begin
    end;
}

