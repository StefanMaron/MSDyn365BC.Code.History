// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.NoSeries;
using System.Reflection;

table 743 "VAT Report Setup"
{
    Caption = 'VAT Report Setup';
    LookupPageID = "VAT Report Setup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary key';
        }
        field(2; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(3; "Modify Submitted Reports"; Boolean)
        {
            Caption = 'Allow Modification';
        }
        field(20; "VAT Return Period No. Series"; Code[20])
        {
            Caption = 'VAT Return Period No. Series';
            TableRelation = "No. Series";
        }
        field(21; "Report Version"; Code[10])
        {
            Caption = 'Report Version';
        }
        field(23; "Update Period Job Frequency"; Option)
        {
            Caption = 'Update Period Job Frequency';
            OptionCaption = 'Never,Daily,Weekly';
            OptionMembers = Never,Daily,Weekly;
        }
        field(24; "Manual Receive Period CU ID"; Integer)
        {
            Caption = 'Manual Receive Period CU ID';
            TableRelation = "CodeUnit Metadata".ID;
        }
        field(25; "Manual Receive Period CU Cap"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Manual Receive Period CU ID")));
            Caption = 'Manual Receive Period CU Cap';
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Auto Receive Period CU ID"; Integer)
        {
            Caption = 'Auto Receive Period CU ID';
            TableRelation = "CodeUnit Metadata".ID;
        }
        field(27; "Auto Receive Period CU Cap"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Auto Receive Period CU ID")));
            Caption = 'Auto Receive Period CU Cap';
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Receive Submitted Return CU ID"; Integer)
        {
            Caption = 'Receive Submitted Return CU ID';
            TableRelation = "CodeUnit Metadata".ID;
        }
        field(29; "Receive Submitted Return CUCap"; Text[250])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
                                                                           "Object ID" = field("Receive Submitted Return CU ID")));
            Caption = 'Receive Submitted Return CUCap';
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Period Reminder Calculation"; DateFormula)
        {
            Caption = 'Period Reminder Calculation';

            trigger OnValidate()
            begin
                if not CheckPositivePeriodReminderCalculation() then
                    Error(PositivePeriodReminderCalcErr);
            end;
        }
        field(31; "Report VAT Base"; Boolean)
        {
            Caption = 'Report VAT Base';
        }
        field(32; "Report VAT Note"; Boolean)
        {
            Caption = 'Report VAT Note';
        }
        field(12100; "Intermediary VAT Reg. No."; Text[20])
        {
            Caption = 'Intermediary VAT Reg. No.';
        }
        field(12101; "Intermediary CAF Reg. No."; Text[5])
        {
            Caption = 'Intermediary CAF Reg. No.';
            Numeric = true;
        }
        field(12102; "Intermediary Date"; Date)
        {
            Caption = 'Intermediary Date';
        }
        field(12150; "Spesometro Communication ID"; Integer)
        {
            Caption = 'Spesometro Communication ID';
        }
        field(12151; "Filter Datifattura Lines"; Boolean)
        {
            Caption = 'Filter Datifattura Lines';
        }
    }

    keys
    {
        key(Key1; "Primary key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    var
        PositivePeriodReminderCalcErr: Label 'The Period Reminder Calculation should be a positive formula. For example, "1M" should be used instead of "-1M".';

    procedure IsPeriodReminderCalculation(): Boolean
    var
        DummyDateFormula: DateFormula;
    begin
        exit("Period Reminder Calculation" <> DummyDateFormula);
    end;

    local procedure CheckPositivePeriodReminderCalculation(): Boolean
    begin
        if not IsPeriodReminderCalculation() then
            exit(true);

        exit(CalcDate("Period Reminder Calculation", WorkDate()) - WorkDate() >= 0);
    end;
}
