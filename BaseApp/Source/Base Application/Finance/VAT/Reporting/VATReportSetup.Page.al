// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using System.Telemetry;

page 743 "VAT Report Setup"
{
    ApplicationArea = VAT;
    Caption = 'VAT Report Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "VAT Report Setup";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Modify Submitted Reports"; Rec."Modify Submitted Reports")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if users can modify VAT reports that have been submitted to the tax authorities. If the field is left blank, users must create a corrective or supplementary VAT report instead.';
                }
                field("Export Cancellation Lines"; Rec."Export Cancellation Lines")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the VAT report includes export cancellation lines.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the company to be included on the VAT report.';
                }
                field("Company Address"; Rec."Company Address")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the address of the company that is submitting the VAT report.';
                }
                field("Company City"; Rec."Company City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the company for the VAT report.';
                }
                field("Report VAT Note"; Rec."Report VAT Note")
                {
                    ApplicationArea = VAT;
                    ToolTip = 'Specifies if the VAT Note field is available for reporting from the VAT Return card page.';
                }
            }
            group(Numbering)
            {
                Caption = 'Numbering';
                field("No. Series"; Rec."No. Series")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number series that will be used for standard VAT reports.';
                }
            }
            group(ZIVIT)
            {
                Caption = 'ZIVIT';
                field("Source Identifier"; Rec."Source Identifier")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the 11 character alphabetic ID that is provided when you register at the processing agency (ZIVIT).';
                }
                field("Transmission Process ID"; Rec."Transmission Process ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the 3 character alphanumeric ID of the transmission process.';
                }
                field("Supplier ID"; Rec."Supplier ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the 3 character alphanumeric ID of the supplier.';
                }
                field(Codepage; Rec.Codepage)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code page for the formats in which you can submit a dataset for a VAT report.';
                }
                field("Registration ID"; Rec."Registration ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the registration ID of the EU Sales List document.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        VatReportTok: Label 'DACH VAT Report', Locked = true;
    begin
        FeatureTelemetry.LogUptake('0001Q0B', VatReportTok, Enum::"Feature Uptake Status"::"Set up");
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;
}

