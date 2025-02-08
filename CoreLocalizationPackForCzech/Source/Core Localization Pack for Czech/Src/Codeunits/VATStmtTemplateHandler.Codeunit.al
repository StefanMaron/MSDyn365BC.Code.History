#if not CLEAN26
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

#pragma warning disable AL0432
codeunit 11780 "VAT Stmt. Template Handler CZL"
{
    ObsoleteState = Pending;
    ObsoleteTag = '26.0';
    ObsoleteReason = 'The codeunit is obsolete and will be removed in version 29.0.';

    [EventSubscriber(ObjectType::Table, Database::"VAT Statement Template", 'OnAfterValidateEvent', 'Page ID', false, false)]
    local procedure UpdateVATStatementReportIDOnAfterValidatePageID(var Rec: Record "VAT Statement Template"; CurrFieldNo: Integer)
    begin
        if CurrFieldNo = 0 then
            if Rec."VAT Statement Report ID" = Report::"VAT Statement" then
                Rec."VAT Statement Report ID" := Report::"VAT Statement CZL";
    end;
}
#endif