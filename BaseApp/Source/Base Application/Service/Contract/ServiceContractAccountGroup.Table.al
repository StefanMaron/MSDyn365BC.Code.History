namespace Microsoft.Service.Contract;

using Microsoft.Finance.GeneralLedger.Account;
using System.Environment.Configuration;

table 5973 "Service Contract Account Group"
{
    Caption = 'Service Contract Account Group';
    DrillDownPageID = "Serv. Contract Account Groups";
    LookupPageID = "Serv. Contract Account Groups";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Non-Prepaid Contract Acc."; Code[20])
        {
            Caption = 'Non-Prepaid Contract Acc.';
            TableRelation = "G/L Account"."No.";

            trigger OnValidate()
            begin
                if "Non-Prepaid Contract Acc." <> '' then begin
                    GLAcc.Get("Non-Prepaid Contract Acc.");
                    if not ApplicationAreaMgmt.IsSalesTaxEnabled() then begin
                        GLAcc.TestField("Gen. Prod. Posting Group");
                        GLAcc.TestField("VAT Prod. Posting Group");
                    end else
                        GLAcc.TestField("Tax Group Code");
                end;
            end;
        }
        field(4; "Prepaid Contract Acc."; Code[20])
        {
            Caption = 'Prepaid Contract Acc.';
            TableRelation = "G/L Account"."No.";

            trigger OnValidate()
            begin
                if "Prepaid Contract Acc." <> '' then begin
                    GLAcc.Get("Prepaid Contract Acc.");
                    if not ApplicationAreaMgmt.IsSalesTaxEnabled() then begin
                        GLAcc.TestField("Gen. Prod. Posting Group");
                        GLAcc.TestField("VAT Prod. Posting Group");
                    end else
                        GLAcc.TestField("Tax Group Code");
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        GLAcc: Record "G/L Account";
        ApplicationAreaMgmt: Codeunit "Application Area Mgmt.";
}

