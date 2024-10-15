// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Setup;

using Microsoft.Finance.VAT.Calculation;

pageextension 31230 "VAT Setup CZL" extends "VAT Setup"
{
#if not CLEAN22

    layout
    {
        modify(VATDate)
        {
            Visible = IsVATDateEnabled and ReplaceVATDateEnabled;
        }
    }
#endif
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
                Visible = NonDeductibleVATVisible;
            }
        }
    }

    trigger OnOpenPage()
#if not CLEAN22
    var
        VATReportingDateMgt: Codeunit "VAT Reporting Date Mgt";
#endif
    begin
#if not CLEAN22
        ReplaceVATDateEnabled := ReplaceVATDateMgtCZL.IsEnabled();
        IsVATDateEnabled := VATReportingDateMgt.IsVATDateEnabled();
#endif
        NonDeductibleVATVisible := NonDeductibleVAT.IsNonDeductibleVATEnabled();
    end;

    var
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
#if not CLEAN22
#pragma warning disable AL0432
        ReplaceVATDateMgtCZL: Codeunit "Replace VAT Date Mgt. CZL";
#pragma warning restore AL0432
        ReplaceVATDateEnabled: Boolean;
        IsVATDateEnabled: Boolean;
#endif
        NonDeductibleVATVisible: Boolean;
}
