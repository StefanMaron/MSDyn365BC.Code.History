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
#if not CLEANSCHEMA31
        field(11000; "Source Identifier"; Text[11])
        {
            Caption = 'Source Identifier';
            ObsoleteReason = 'This field is no longer used in the new VIES ELMA XML export format.';
#if CLEAN28
            ObsoleteState = Removed;
            ObsoleteTag = '31.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
#endif
        }
        field(11001; "Transmission Process ID"; Text[3])
        {
            Caption = 'Transmission Process ID';
            ObsoleteReason = 'This field is no longer used in the new VIES ELMA XML export format.';
#if CLEAN28
            ObsoleteState = Removed;
            ObsoleteTag = '31.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
#endif
        }
        field(11002; "Supplier ID"; Text[3])
        {
            Caption = 'Supplier ID';
            ObsoleteReason = 'This field is no longer used in the new VIES ELMA XML export format.';
#if CLEAN28
            ObsoleteState = Removed;
            ObsoleteTag = '31.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
#endif
        }
        field(11003; Codepage; Option)
        {
            Caption = 'Codepage';
            OptionCaption = 'IBM-850,EBCDIC273,EBCDIC1141';
            OptionMembers = "IBM-850",EBCDIC273,EBCDIC1141;
            ObsoleteReason = 'This field is no longer used in the new VIES ELMA XML export format.';
#if CLEAN28
            ObsoleteState = Removed;
            ObsoleteTag = '31.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
#endif
        }
        field(11004; "Registration ID"; Text[6])
        {
            Caption = 'Registration ID';
            ObsoleteReason = 'This field is no longer used in the new VIES ELMA XML export format.';
#if CLEAN28
            ObsoleteState = Removed;
            ObsoleteTag = '31.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '28.0';
#endif
        }
#endif
        field(11005; "Export Cancellation Lines"; Boolean)
        {
            Caption = 'Export Cancellation Lines';
        }
        field(11006; "Company Name"; Text[100])
        {
            Caption = 'Company Name';
        }
        field(11007; "Company Address"; Text[30])
        {
            Caption = 'Company Address';
        }
        field(11008; "Company City"; Text[30])
        {
            Caption = 'Company City';
        }
        field(11009; "BOP User Account ID"; Text[20])
        {
            Caption = 'BOP User Account ID';
            Numeric = true;
            ToolTip = 'Specifies the 10-digit BOP user account ID (Benutzerkonto-ID) required for ELMA data transmission. This ID is displayed in your BOP account under Mein BOP.';

            trigger OnValidate()
            begin
                if (Rec."BOP User Account ID" <> '') and (StrLen(Rec."BOP User Account ID") <> 10) then
                    Error(BOPUserAccountIDLengthErr);
            end;
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
        BOPUserAccountIDLengthErr: Label 'The BOP User Account ID must be exactly 10 digits.';
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
