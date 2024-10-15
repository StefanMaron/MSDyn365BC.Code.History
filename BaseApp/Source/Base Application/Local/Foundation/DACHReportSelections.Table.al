﻿// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Reporting;

using System.Reflection;

table 26100 "DACH Report Selections"
{
    Caption = 'DACH Report Selections';
    DataClassification = CustomerContent;
    ObsoleteReason = 'Replaced by W1 table Report Selections';
#if not CLEAN25 
    ObsoleteState = Pending;
    ObsoleteTag = '25.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '28.0';
#endif

    fields
    {
        field(1; Usage; Option)
        {
            Caption = 'Usage';
            OptionCaption = 'Intrastat Checklist,Intrastat Form,Intrastat Disk,Intrastat Disklabel,,,,,,VAT Statement,Sales VAT Acc. Proof,VAT Statement Schedule,,,,,,Phys. Invt. Order Test,Phys. Invt. Order,Posted Phys. Invt. Order,Phys. Invt. Recording,Posted Phys. Invt. Recording,,,,,,Delivery Reminder Test,Issued Delivery Reminder,,,,,,S.Arch. Blanket Order,P.Arch. Blanket Order';
            OptionMembers = "Intrastat Checklist","Intrastat Form","Intrastat Disk","Intrastat Disklabel",,,,,,"VAT Statement","Sales VAT Acc. Proof","VAT Statement Schedule",,,,,,"Phys. Invt. Order Test","Phys. Invt. Order","Posted Phys. Invt. Order","Phys. Invt. Recording","Posted Phys. Invt. Recording",,,,,,"Delivery Reminder Test","Issued Delivery Reminder",,,,,,"S.Arch. Blanket Order","P.Arch. Blanket Order";
        }
        field(2; Sequence; Code[10])
        {
            Caption = 'Sequence';
            Numeric = true;
        }
        field(3; "Report ID"; Integer)
        {
            Caption = 'Report ID';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Report));
#if not CLEAN25
            trigger OnValidate()
            begin
                CalcFields("Report Name");
            end;
#endif
        }
        field(4; "Report Name"; Text[80])
        {
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Report),
                                                                           "Object ID" = field("Report ID")));
            Caption = 'Report Name';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; Usage, Sequence)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

#if not CLEAN25
    var
        DACHReportSelection2: Record "DACH Report Selections";

    [Obsolete('Replaced by W1 table Report Selections', '25.0')]
    [Scope('OnPrem')]
    procedure NewRecord()
    begin
        DACHReportSelection2.SetRange(Usage, Usage);
        if DACHReportSelection2.FindLast() and (DACHReportSelection2.Sequence <> '') then
            Sequence := IncStr(DACHReportSelection2.Sequence)
        else
            Sequence := '1';
    end;
#endif
}
