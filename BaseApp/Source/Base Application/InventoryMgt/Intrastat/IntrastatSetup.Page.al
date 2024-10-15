#if not CLEAN22
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using System.Telemetry;

page 328 "Intrastat Setup"
{
    ApplicationArea = BasicEU;
    Caption = 'Intrastat Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    SourceTable = "Intrastat Setup";
    UsageCategory = Administration;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Report Receipts"; Rec."Report Receipts")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies that you must include arrivals of received goods in Intrastat reports.';
                }
                field("Report Shipments"; Rec."Report Shipments")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies that you must include shipments of dispatched items in Intrastat reports.';
                }
                field("Intrastat Contact Type"; Rec."Intrastat Contact Type")
                {
                    ApplicationArea = BasicEU;
                    OptionCaption = ' ,Contact,Vendor';
                    ToolTip = 'Specifies the Intrastat contact type.';

                    trigger OnValidate()
                    begin
                        SetupCompleted()
                    end;
                }
                field("Intrastat Contact No."; Rec."Intrastat Contact No.")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the Intrastat contact.';

                    trigger OnValidate()
                    begin
                        SetupCompleted()
                    end;
                }
                field("Company VAT No. on File"; Rec."Company VAT No. on File")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the company''s VAT registration number exports to the Intrastat file. 0 is the value of the VAT Reg. No. field, 1 adds the EU country code as a prefix, and 2 removes the EU country code.';
                }
                field("Vend. VAT No. on File"; Rec."Vend. VAT No. on File")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how a vendor''s VAT registration number exports to the Intrastat file. 0 is the value of the VAT Reg. No. field, 1 adds the EU country code as a prefix, and 2 removes the EU country code.';
                }
                field("Cust. VAT No. on File"; Rec."Cust. VAT No. on File")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how a customer''s VAT registration number exports to the Intrastat file. 0 is the value of the VAT Reg. No. field, 1 adds the EU country code as a prefix, and 2 removes the EU country code.';
                }
            }
            group("Default Transactions")
            {
                Caption = 'Default Transactions';
                field("Default Transaction Type"; Rec."Default Trans. - Purchase")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the default transaction type for regular sales shipments and service shipments, and purchase receipts.';
                }
                field("Default Trans. Type - Returns"; Rec."Default Trans. - Return")
                {
                    ApplicationArea = BasicEU;
                    ToolTip = 'Specifies the default transaction type for sales returns and service returns, and purchase returns';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(AdvancedIntrastatChecklistSetup)
            {
                ApplicationArea = BasicEU;
                Caption = 'Advanced Intrastat Checklist Setup';
                Image = Column;
                RunObject = Page "Advanced Intrastat Checklist";
                ToolTip = 'View and edit fields to be verified by the Intrastat journal check.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(AdvancedIntrastatChecklistSetup_Promoted; AdvancedIntrastatChecklistSetup)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        FeatureTelemetry.LogUptake('0000FAS', IntrastatTok, Enum::"Feature Uptake Status"::Discovered);
        Rec.Init();
        if not Rec.Get() then
            Rec.Insert(true);
    end;

    local procedure SetupCompleted()
    begin
        if Rec."Intrastat Contact No." <> '' then
            FeatureTelemetry.LogUptake('0000FAD', IntrastatTok, Enum::"Feature Uptake Status"::"Set up");
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        IntrastatTok: Label 'Intrastat', Locked = true;
}
#endif
