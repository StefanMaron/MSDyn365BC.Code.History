namespace Microsoft.Warehouse.Ledger;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Journal;
using Microsoft.Utilities;
using System.Security.AccessControl;
using Microsoft.Foundation.NoSeries;

table 7313 "Warehouse Register"
{
    Caption = 'Warehouse Register';
    LookupPageID = "Warehouse Registers";
    Permissions = TableData "Warehouse Register" = ri;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; "From Entry No."; Integer)
        {
            Caption = 'First Entry No.';
            TableRelation = "Warehouse Entry";
        }
        field(3; "To Entry No."; Integer)
        {
            Caption = 'Last Entry No.';
            TableRelation = "Warehouse Entry";
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
        }
        field(7; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Item Journal Batch".Name;
        }
        field(9; "Creation Time"; Time)
        {
            Caption = 'Creation Time';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; "Source Code")
        {
        }
    }

    fieldgroups
    {
    }

    procedure InsertRecord(UseLegacyPosting: Boolean)
    begin
        if UseLegacyPosting then
            Rec.Insert()
        else
            InsertRecord();
    end;

    procedure InsertRecord()
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        if not Rec.Insert() then begin
            SequenceNoMgt.RebaseSeqNo(DATABASE::"Warehouse Register");
            "No." := SequenceNoMgt.GetNextSeqNo(DATABASE::"Warehouse Register");
            Rec.Insert();
        end;
    end;

    procedure GetNextEntryNo(UseLegacyPosting: Boolean): Integer
    begin
        if not UseLegacyPosting then
            exit(GetNextEntryNo());
        Rec.LockTable();
        exit(GetLastEntryNo() + 1);
    end;

    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(DATABASE::"Warehouse Register"));
    end;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("No.")))
    end;

    procedure Lock()
    begin
        LockTable();
        if FindLast() then;
    end;
}

