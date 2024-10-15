namespace Microsoft.Bank.PositivePay;

using Microsoft.Bank.BankAccount;
using System.IO;
using System.Utilities;

table 1231 "Positive Pay Entry"
{
    Caption = 'Positive Pay Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            NotBlank = false;
            TableRelation = "Bank Account"."No.";

            trigger OnValidate()
            begin
                if "Bank Account No." <> '' then
                    "Upload Date-Time" := CurrentDateTime
                else
                    "Upload Date-Time" := CreateDateTime(0D, 0T);
            end;
        }
        field(2; "Upload Date-Time"; DateTime)
        {
            Caption = 'Upload Date-Time';
            Editable = false;
        }
        field(5; "Last Upload Date"; Date)
        {
            Caption = 'Last Upload Date';
        }
        field(6; "Last Upload Time"; Time)
        {
            Caption = 'Last Upload Time';
        }
        field(7; "Number of Uploads"; Integer)
        {
            Caption = 'Number of Uploads';
        }
        field(8; "Number of Checks"; Integer)
        {
            Caption = 'Number of Checks';
        }
        field(9; "Number of Voids"; Integer)
        {
            Caption = 'Number of Voids';
        }
        field(10; "Check Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromBank();
            AutoFormatType = 1;
            Caption = 'Check Amount';
        }
        field(11; "Void Amount"; Decimal)
        {
            AutoFormatExpression = GetCurrencyCodeFromBank();
            AutoFormatType = 1;
            Caption = 'Void Amount';
        }
        field(12; "Confirmation Number"; Text[20])
        {
            Caption = 'Confirmation Number';
        }
        field(13; "Exported File"; BLOB)
        {
            Caption = 'Exported File';
        }
    }

    keys
    {
        key(Key1; "Bank Account No.", "Upload Date-Time")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        PositivePayFileNotFoundErr: Label 'The original positive pay export file was not found.';

    local procedure GetCurrencyCodeFromBank(): Code[10]
    var
        BankAccount: Record "Bank Account";
    begin
        if "Bank Account No." = '' then
            exit('');

        if BankAccount.Get("Bank Account No.") then
            exit(BankAccount."Currency Code");

        exit('');
    end;

    [Scope('OnPrem')]
    procedure Reexport()
    var
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        ReexportFileName: Text[50];
        ExportDate: Date;
    begin
        TempBlob.FromRecord(Rec, FieldNo("Exported File"));

        if not TempBlob.HasValue() then
            Error(PositivePayFileNotFoundErr);

        ExportDate := DT2Date("Upload Date-Time");
        ReexportFileName := "Bank Account No." + Format(ExportDate, 0, '<Month><Day><Year4>');
        FileMgt.BLOBExport(TempBlob, StrSubstNo('%1.TXT', ReexportFileName), true);
    end;
}

