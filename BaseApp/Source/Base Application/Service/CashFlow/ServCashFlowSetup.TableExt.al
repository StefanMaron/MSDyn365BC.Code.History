namespace Microsoft.Service.CashFlow;

using Microsoft.CashFlow.Setup;
using Microsoft.CashFlow.Account;
using Microsoft.Service.Document;

tableextension 6471 "Serv. Cash Flow Setup" extends "Cash Flow Setup"
{
    fields
    {
        field(10; "Service CF Account No."; Code[20])
        {
            AccessByPermission = TableData "Service Header" = R;
            Caption = 'Service CF Account No.';
            DataClassification = CustomerContent;
            TableRelation = "Cash Flow Account";

            trigger OnValidate()
            begin
                CheckAccountType("Service CF Account No.");
            end;
        }
    }
}