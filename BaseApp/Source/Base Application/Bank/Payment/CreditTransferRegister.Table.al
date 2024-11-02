namespace Microsoft.Bank.Payment;

using Microsoft.Bank.BankAccount;
using System.IO;
using System.Security.AccessControl;
using System.Utilities;

table 1205 "Credit Transfer Register"
{
    Caption = 'Credit Transfer Register';
    DataCaptionFields = Identifier, "Created Date-Time";
    DrillDownPageID = "Credit Transfer Registers";
    LookupPageID = "Credit Transfer Registers";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer)
        {
            Caption = 'No.';
        }
        field(2; Identifier; Code[20])
        {
            Caption = 'Identifier';
        }
        field(3; "Created Date-Time"; DateTime)
        {
            Caption = 'Created Date-Time';
        }
        field(4; "Created by User"; Code[50])
        {
            Caption = 'Created by User';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(5; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = 'Canceled,File Created,File Re-exported';
            OptionMembers = Canceled,"File Created","File Re-exported";
        }
        field(6; "No. of Transfers"; Integer)
        {
            CalcFormula = count("Credit Transfer Entry" where("Credit Transfer Register No." = field("No.")));
            Caption = 'No. of Transfers';
            FieldClass = FlowField;
        }
        field(7; "From Bank Account No."; Code[20])
        {
            Caption = 'From Bank Account No.';
            TableRelation = "Bank Account";
        }
        field(8; "From Bank Account Name"; Text[100])
        {
            CalcFormula = lookup("Bank Account".Name where("No." = field("From Bank Account No.")));
            Caption = 'From Bank Account Name';
            FieldClass = FlowField;
        }
        field(9; "Exported File"; BLOB)
        {
            Caption = 'Exported File';
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
        key(Key2; Status)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        CreditTransferEntry: Record "Credit Transfer Entry";
    begin
        CreditTransferEntry.SetRange("Credit Transfer Register No.", "No.");
        CreditTransferEntry.DeleteAll();
    end;

    var
        PaymentsFileNotFoundErr: Label 'The original payment file was not found.\Export a new file from the Payment Journal window.';
        ExportToServerFile: Boolean;

    procedure CreateNew(NewIdentifier: Code[20]; NewBankAccountNo: Code[20])
    begin
        Reset();
        LockTable();
        if FindLast() then;
        Init();
        "No." += 1;
        Identifier := NewIdentifier;
        "Created Date-Time" := CurrentDateTime;
        "Created by User" := UserId;
        "From Bank Account No." := NewBankAccountNo;
        Insert();
    end;

    procedure SetStatus(NewStatus: Option)
    begin
        LockTable();
        Find();
        Status := NewStatus;
        Modify();
    end;

    procedure Reexport()
    var
        CreditTransReExportHistory: Record "Credit Trans Re-export History";
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
    begin
        TempBlob.FromRecord(Rec, FieldNo("Exported File"));

        if not TempBlob.HasValue() then
            Error(PaymentsFileNotFoundErr);

        CreditTransReExportHistory.Init();
        CreditTransReExportHistory."Credit Transfer Register No." := "No.";
        CreditTransReExportHistory.Insert(true);

        if FileMgt.BLOBExport(TempBlob, StrSubstNo('%1.XML', Identifier), not ExportToServerFile) <> '' then begin
            Status := Status::"File Re-exported";
            Modify();
        end;
    end;

    procedure SetFileContent(var DataExch: Record "Data Exch.")
    begin
        LockTable();
        Find();
        DataExch.CalcFields("File Content");
        "Exported File" := DataExch."File Content";
        Modify();
    end;

    procedure EnableExportToServerFile()
    begin
        ExportToServerFile := true;
    end;
}

