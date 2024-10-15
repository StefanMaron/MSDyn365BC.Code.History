namespace Microsoft.Finance.GeneralLedger.Ledger;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 45 "G/L Register"
{
    Caption = 'G/L Register';
    LookupPageID = "G/L Registers";
    Permissions = TableData "G/L Register" = rimd;
    DataClassification = CustomerContent;

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
        }
        field(3; "To Entry No."; Integer)
        {
            Caption = 'To Entry No.';
            TableRelation = "G/L Entry";
        }
        field(4; "Creation Date"; Date)
        {
            Caption = 'Creation Date';
#if not CLEAN24
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
#endif
            ObsoleteReason = 'Use the system audit field "System Created at" instead.';
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
        }
        field(7; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(8; "From VAT Entry No."; Integer)
        {
            Caption = 'From VAT Entry No.';
            TableRelation = "VAT Entry";
        }
        field(9; "To VAT Entry No."; Integer)
        {
            Caption = 'To VAT Entry No.';
            TableRelation = "VAT Entry";
        }
        field(10; Reversed; Boolean)
        {
            Caption = 'Reversed';
        }
        field(11; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
#if not CLEAN24
            ObsoleteState = Pending;
            ObsoleteTag = '24.0';
#else
            ObsoleteState = Removed;
            ObsoleteTag = '26.0';
#endif
            ObsoleteReason = 'Use the system audit field "System Created at" instead.';
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
#if not CLEAN24
        key(Key2; "Creation Date")
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Creation Date is obsoleted';
            ObsoleteTag = '24.0';
        }
#endif
#if not CLEAN24
        key(Key3; "Source Code", "Journal Batch Name", "Creation Date")
        {
        }
#else
        key(Key3; "Source Code", "Journal Batch Name")
        {
        }
#endif
        key(key4; "From Entry No.", "To Entry No.")
        {
#if not CLEAN24
            IncludedFields = "Creation Date";
#endif
        }
    }

    fieldgroups
    {
#if not CLEAN24
        fieldgroup(DropDown; "No.", "From Entry No.", "To Entry No.", "Creation Date", "Source Code")
        {
        }
#else
        fieldgroup(DropDown; "No.", "From Entry No.", "To Entry No.", SystemCreatedAt, "Source Code")
        {
        }
#endif

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
#if not CLEAN24            
        "Creation Date" := Today;
        "Creation Time" := Time;
#endif
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

