// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Payroll;

xmlport 1660 "Import Payroll"
{
    Caption = 'Import Payroll';
    Direction = Import;
    FieldDelimiter = '<None>';
    FieldSeparator = '<TAB>';
    Format = VariableText;
    FormatEvaluate = Legacy;
    TextEncoding = WINDOWS;

    schema
    {
        textelement(Root)
        {
            tableelement("Payroll Import Buffer"; "Payroll Import Buffer")
            {
                XmlName = 'PayrollBuffer';
                fieldelement(PostingDate; "Payroll Import Buffer"."Transaction date")
                {
                }
                fieldelement(Account; "Payroll Import Buffer"."Account No.")
                {
                }
                fieldelement(Amount; "Payroll Import Buffer".Amount)
                {
                }
                fieldelement(Description; "Payroll Import Buffer".Description)
                {
                }

                trigger OnBeforeInsertRecord()
                begin
                    I += 1;
                    "Payroll Import Buffer"."Entry No." := I;
                end;
            }
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    trigger OnInitXmlPort()
    begin
        I := 0;
    end;

    var
        I: Integer;
}

