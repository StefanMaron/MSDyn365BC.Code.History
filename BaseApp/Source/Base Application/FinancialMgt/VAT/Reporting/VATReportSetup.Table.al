﻿// ------------------------------------------------------------------------------------------------
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

    fields
    {
        field(1; "Primary key"; Code[10])
        {
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
        field(22; "Period Reminder Time"; Integer)
        {
            Caption = 'Period Reminder Time';
            MinValue = 0;
            ObsoleteReason = 'Redesigned to a new field "Period Reminder Calculation"';
            ObsoleteState = Removed;
            ObsoleteTag = '20.0';
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
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
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
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
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
            CalcFormula = Lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Codeunit),
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
        field(4800; "VATGroup Role"; Option)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4700 VAT Group Role';
            ObsoleteTag = '18.0';
            OptionMembers = ,Representative,Member;
        }
        field(4801; ApprovedMembers; Integer)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4701 Approved Members';
            ObsoleteTag = '18.0';
        }
        field(4802; "GroupMember ID"; Guid)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4702 Group Member ID';
            ObsoleteTag = '18.0';
        }
        field(4803; "GroupRepresentative API URL"; Text[250])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4703 Group Representative API URL';
            ObsoleteTag = '18.0';
        }
        field(4804; AuthenticationType; Option)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4704 Authentication Type';
            ObsoleteTag = '18.0';
            OptionMembers = WebServiceAccessKey,OAuth2,WindowsAuthentication;
        }
        field(4805; "UserName Key"; Guid)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4705 User Name Key';
            ObsoleteTag = '18.0';
        }
        field(4806; "WebService Access Key Key"; Guid)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4706 Web Service Access Key Key';
            ObsoleteTag = '18.0';
        }
        field(4807; "GroupRepresentative Company"; Text[30])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4707 Group Representative Company';
            ObsoleteTag = '18.0';
        }
        field(4808; "ClientID Key"; Guid)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4708 Client ID Key';
            ObsoleteTag = '18.0';
        }
        field(4809; "ClientSecret Key"; Guid)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4709 Client Secret Key';
            ObsoleteTag = '18.0';
        }
        field(4810; AuthorityURL; Text[250])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4710 Authority URL';
            ObsoleteTag = '18.0';
        }
        field(4811; ResourceURL; Text[250])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4711 Resource URL';
            ObsoleteTag = '18.0';
        }
        field(4812; RedirectURL; Text[250])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4712 Redirect URL';
            ObsoleteTag = '18.0';
        }
        field(4814; "GroupSettlement Account"; Code[20])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4714 Group Settlement Account';
            ObsoleteTag = '18.0';
        }
        field(4815; "VATSettlement Account"; Code[20])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4715 VAT Settlement Account';
            ObsoleteTag = '18.0';
        }
        field(4816; "VATDue Box No."; Text[30])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4716 VAT Due Box No.';
            ObsoleteTag = '18.0';
        }
        field(4817; "GroupSettle. Gen. Jnl. Templ."; Code[10])
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4717 Redirect Group Settle. Gen. Jnl. Templ.';
            ObsoleteTag = '18.0';
        }
        field(4818; "VATGroup BC Version"; Option)
        {
            ObsoleteState = Removed;
            ObsoleteReason = 'Moved to VAT Group Management extension field 4718 VAT Group BC Version';
            ObsoleteTag = '18.0';
            OptionMembers = BC,NAV2018,NAV2017;
        }
        field(11000; "Source Identifier"; Text[11])
        {
            Caption = 'Source Identifier';
        }
        field(11001; "Transmission Process ID"; Text[3])
        {
            Caption = 'Transmission Process ID';
        }
        field(11002; "Supplier ID"; Text[3])
        {
            Caption = 'Supplier ID';
        }
        field(11003; Codepage; Option)
        {
            Caption = 'Codepage';
            OptionCaption = 'IBM-850,EBCDIC273,EBCDIC1141';
            OptionMembers = "IBM-850",EBCDIC273,EBCDIC1141;
        }
        field(11004; "Registration ID"; Text[6])
        {
            Caption = 'Registration ID';
        }
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

