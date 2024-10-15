// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Registration;

page 246 "VAT Reg. No. Srv. Templates"
{
    PageType = List;
    ApplicationArea = Basic, Suite;
    UsageCategory = Administration;
    SourceTable = "VAT Reg. No. Srv. Template";
    Caption = 'VAT Reg. No. Validation Templates';

    layout
    {
        area(Content)
        {
            repeater(TemplateList)
            {
                field(Code; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the template code.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the country/region code.';
                }
                field("Account Type"; Rec."Account Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account type.';
                }
                field("Account No."; Rec."Account No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account number.';
                }
                field("Validate Name"; Rec."Validate Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the name value is validated.';
                }
                field("Validate Street"; Rec."Validate Street")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the street value is validated.';
                }
                field("Validate City"; Rec."Validate City")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the city value is validated.';
                }
                field("Validate Post Code"; Rec."Validate Post Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the post code value is validated.';
                }
                field("Ignore Details"; Rec."Ignore Details")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to exclude any detailed information that the validation service returns. Choose the field to view all validation details.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        VATRegNoSrvConfig: Record "VAT Reg. No. Srv Config";
    begin
        VATRegNoSrvConfig.Get();
        Rec.CheckInitDefaultTemplate(VATRegNoSrvConfig);
    end;
}
