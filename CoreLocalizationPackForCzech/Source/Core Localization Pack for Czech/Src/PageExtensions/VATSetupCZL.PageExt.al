// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.VAT.Calculation;

pageextension 31230 "VAT Setup CZL" extends "VAT Setup"
{


    layout
    {
#if not CLEAN22
        modify(VATDate)
        {
            Visible = IsVATDateEnabled and ReplaceVATDateEnabled;
        }
#endif
        addafter("Enable Non-Deductible VAT")
        {
            field("Enable Non-Deductible VAT CZL"; Rec."Enable Non-Deductible VAT CZL")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies if the Non-Deductible VAT CZ feature is enabled.';
                Editable = Rec."Enable Non-Deductible VAT" and not Rec."Enable Non-Deductible VAT CZL";
            }
        }
    }

    actions
    {
        addlast(VATReporting)
        {
            action("Non-Deductible VAT Setup CZL")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Non-Deductible VAT Setup';
                Image = VATPostingSetup;
                RunObject = Page "Non-Deductible VAT Setup CZL";
                ToolTip = 'Set up VAT coefficient correction.';
                Visible = Rec."Enable Non-Deductible VAT CZL";
            }
        }
    }
#if not CLEAN22
    trigger OnOpenPage()
    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
    begin
        ReplaceVATDateEnabled := ReplaceVATDateMgtCZL.IsEnabled();
        IsVATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
    end;

    var
#pragma warning disable AL0432
        ReplaceVATDateMgtCZL: Codeunit "Replace VAT Date Mgt. CZL";
#pragma warning restore AL0432
        ReplaceVATDateEnabled: Boolean;
        IsVATDateEnabled: Boolean;
#endif
}
